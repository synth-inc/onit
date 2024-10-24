import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import multer from 'multer';
import { CustomError } from '@utils/CustomError';
import { ChatCompletionMessageParam } from 'openai/resources/chat/completions';
import fs from 'fs';
import path from 'path';

const upload = multer({ dest: 'uploads/' });

const processInput = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    const { instructions } = req.body;
    let { input, model } = req.body
    const uploadedFiles = req.files as Express.Multer.File[];

    if (!instructions) {
        throw new CustomError('Instructions are required', 400);
    }

    const openai = new OpenAI();

    try {
        let messages: ChatCompletionMessageParam[] = [];
        let fileContents = '';

        if (input && typeof input === 'string') {
            try {
                input = JSON.parse(input);
            } catch (parseError) {
                throw new CustomError('Invalid JSON in "input" field', 400);
            }
        }

        if (model && typeof model === 'string') {
            try {
                model = JSON.parse(model);
            } catch (parseError) {
                throw new CustomError('Invalid JSON in "model" field', 400);
            }
        }

        const { application, selectedText } = input || {};

        // Loop through each uploaded file and append its content
        if (uploadedFiles && uploadedFiles.length > 0) {
            for (const file of uploadedFiles) {
                const filePath = path.join(__dirname, '..', file.path);
                const fileContent = fs.readFileSync(filePath, 'utf-8');

                fileContents += `\n\nFile: ${file.originalname}\nContent:\n${fileContent}`;

                // Clean up the temporary file
                fs.unlinkSync(filePath);
            }
        }

        if (application && input) {
            let userMessage = instructions;

            if (selectedText) {
                userMessage += `\n\nText:\n${selectedText}`;
            }

            if (fileContents) {
                userMessage += fileContents;
            }

            messages = [
                {
                    role: 'system',
                    content: `Based on the provided instructions, either modify the given text from the application ${application} or answer any questions related to it. Provide the response without any additional comments, formatting, coding language, or labels. Provide the text raw and ready to go.`,
                },
                {
                    role: 'user',
                    content: userMessage,
                },
            ];
        } else {
            let userMessage = instructions;
            
            if (fileContents) {
                userMessage += fileContents;
            }

            messages = [
                {
                    role: 'system',
                    content: `Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments, formatting, coding language, or labels. Provide the output raw and ready to go.`,
                },
                {
                    role: 'user',
                    content: userMessage,
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
