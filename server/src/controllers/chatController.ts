import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { CustomError } from '@utils/CustomError';
import { ChatCompletionMessageParam } from 'openai/resources/chat/completions';

const processInput = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    const { instructions, input } = req.body;
    const { application, selectedText } = input || {};

    if (!instructions) {
        throw new CustomError('Instructions are required', 400);
    }

    const openai = new OpenAI();

    try {
        let userMessage = instructions;
        if (selectedText) {
            userMessage += `\n\nText:\n${selectedText}`;
        }

        const messages: ChatCompletionMessageParam[] = [
            {
                role: 'system',
                content: `Modify the given text from the application ${application} according to the instructions and provide **only** the modified text without any additional comments or labels.`,
            },
            {
                role: 'user',
                content: userMessage,
            },
        ]

        const response = await openai.chat.completions.create({
            model: 'gpt-4o',
            messages: messages,
        });

        const output = response.choices[0].message.content?.trim();
        res.json({ output });
    } catch (error: any) {
        next(error);
    }
};

export default { processInput };
