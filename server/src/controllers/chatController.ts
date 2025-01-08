import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';
import multer from 'multer';
import { CustomError } from '@utils/CustomError';
import { ChatCompletionMessageParam } from 'openai/resources/chat/completions';
import fs from 'fs';
import { TextBlock } from '@anthropic-ai/sdk/resources/messages';

type ModelProvider = 'openai' | 'anthropic';

interface ModelInfo {
    provider: ModelProvider;
    capabilities: {
        vision?: boolean;
        function_calling?: boolean;
    };
}

const MODEL_CONFIGS: Record<string, ModelInfo> = {
    // OpenAI Models
    'gpt-4': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-4-turbo-preview': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-4-vision-preview': { provider: 'openai', capabilities: { vision: true, function_calling: true } },
    'gpt-3.5-turbo': { provider: 'openai', capabilities: { function_calling: true } },
    'gpt-3.5-turbo-16k': { provider: 'openai', capabilities: { function_calling: true } },
    
    // Anthropic Models
    'claude-3-opus-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-3-sonnet-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-3-haiku-20240229': { provider: 'anthropic', capabilities: { vision: true } },
    'claude-2.1': { provider: 'anthropic', capabilities: {} },
    'claude-2.0': { provider: 'anthropic', capabilities: {} },
    'claude-instant-1.2': { provider: 'anthropic', capabilities: {} }
};

const upload = multer({ dest: 'uploads/' });

const processInput = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    console.log('Received req.body:', req.body);
    console.log('Received req.files:', req.files);    

    const { instructions, images } = req.body;
    let { input, model } = req.body
    const uploadedFiles = req.files as Express.Multer.File[];

    const openai = new OpenAI();
    const anthropic = new Anthropic();

    try {
        if (!instructions) {
            throw new CustomError('Instructions are required', 400);
        }    

        let messages: ChatCompletionMessageParam[] = [];
        let fileContents = '';

        if (input && typeof input === 'string' && input.trim() !== '') {
            try {
                input = JSON.parse(input);
            } catch (parseError) {
                throw new CustomError('Invalid JSON in "input" field', 400);
            }
        } else {
            input = null;
        }

        if (!model || typeof model !== 'string' || model.trim() === '') {
            model = 'gpt-4';
        }

        const modelConfig = MODEL_CONFIGS[model];
        if (!modelConfig) {
            throw new CustomError(`Unsupported model: ${model}`, 400);
        }

        // Check if model supports vision when images are provided
        if (images?.length > 0 && !modelConfig.capabilities.vision) {
            throw new CustomError(`Model ${model} does not support vision/image inputs`, 400);
        }
        
        if (!instructions || typeof instructions !== 'string' || instructions.trim() === '') {
            throw new CustomError('Instructions are required and cannot be empty', 400);
        }        

        const { application, selectedText } = input || {};

        if (uploadedFiles && uploadedFiles.length > 0) {
            for (const file of uploadedFiles) {
                console.log('Reading file at path:', file.path);
                const fileContent = fs.readFileSync(file.path, 'utf-8');

                fileContents += `\n\nFile: ${file.originalname}\nContent:\n${fileContent}`;

                // Clean up the temporary file
                fs.unlinkSync(file.path);
            }
        }

        let userMessage = instructions;

        if (fileContents) {
            userMessage += fileContents;
        }

        if (selectedText) {
            userMessage += `\n\nSelected Text: ${selectedText}`;
        }

        const userContent = [
            { type: 'text', text: userMessage },
            ...(images || []).map((url: string) => ({
                type: 'image_url',
                image_url: { url },
            })),
        ];

        if (application) {
            messages = [
                {
                    role: 'system',
                    content: `Based on the provided instructions, either modify the given text from the application ${application} or answer any questions related to it. Provide the response without any additional comments. Provide the text ready to go.`,
                },
                {
                    role: 'user',
                    content: userContent,
                },
            ];
        } else {
            messages = [
                {
                    role: 'system',
                    content: `Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.`,
                },
                {
                    role: 'user',
                    content: userContent,
                },
            ];
        }

        let output: string;
        
        if (modelConfig.provider === 'anthropic') {
            const systemMessage = messages[0].content as string;
            const userContent = messages[1].content as any[];
            
            // For Claude 3 models, we can pass images directly
            const isVisionModel = modelConfig.capabilities.vision;
            const userMessage = isVisionModel
                ? userContent
                : userContent.map(content => {
                    if (content.type === 'text') return content.text;
                    if (content.type === 'image_url') return `[Image: ${content.image_url.url}]`;
                    return '';
                }).join('\n');

            const response = await anthropic.messages.create({
                model: model,
                system: systemMessage,
                messages: [{ role: 'user', content: userMessage }],
                max_tokens: 4096,
            });
            output = response.content
                .filter((block) => block.type === 'text')
                .map((block) => (block as TextBlock).text)
                .join('');
        } else {
            const response = await openai.chat.completions.create({
                model: model,
                messages: messages,
            });

            output = response.choices[0].message.content?.trim() || '';
        }
        res.json({ output });
    } catch (error: any) {
        next(error);
    }
};

export default { processInput, upload };
