import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { CustomError } from '@utils/CustomError';
import { ChatCompletionMessageParam } from 'openai/resources/chat/completions';

const processInput = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    const { instructions, input, model } = req.body;
    const { application, selectedText } = input || {};

    if (!instructions) {
        throw new CustomError('Instructions are required', 400);
    }

    const openai = new OpenAI();

    try {
        let messages: ChatCompletionMessageParam[] = [];

        if (application && input) {
            let userMessage = instructions;

            if (selectedText) {
                userMessage += `\n\nText:\n${selectedText}`;
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
            messages = [
                {
                    role: 'system',
                    content: `Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments, formatting, coding language, or labels. Provide the output raw and ready to go.`,
                },
                {
                    role: 'user',
                    content: instructions,
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

export default { processInput };
