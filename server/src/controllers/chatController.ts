import { Request, Response, NextFunction } from 'express';
import OpenAI from 'openai';
import { CustomError } from '@utils/CustomError';

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
            userMessage += `\nApplication: ${application}\nSelected Text: ${selectedText}`;
        }

        const response = await openai.chat.completions.create({
            model: 'gpt-3.5-turbo',
            messages: [{ role: 'user', content: userMessage }],
        });

        const output = response.choices[0].message.content?.trim();
        res.json({ output });
    } catch (error: any) {
        next(error);
    }
};

export default { processInput };
