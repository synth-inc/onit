import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import multer from 'multer';
import { CustomError } from '@utils/CustomError';
import { ChatCompletionMessageParam } from 'openai/resources/chat/completions';
import fs from 'fs';

const upload = multer({ dest: 'uploads/' });

const processInput = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    console.log('Received req.body:', req.body);
    console.log('Received req.files:', req.files);    

    const { instructions, images } = req.body;
    let { input, model } = req.body
    const uploadedFiles = req.files as Express.Multer.File[];

    const openai = new OpenAI();

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
            model = 'gpt-4o';
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

        const response = await openai.chat.completions.create({
            model: model || 'gpt-4',
            messages: messages,
        });

        const output = response.choices[0].message.content?.trim();
        res.json({ output });
    } catch (error: any) {
        next(error);
    }
};

export default { processInput, upload };
