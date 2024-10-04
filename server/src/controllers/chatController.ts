// src/controllers/chatController.ts
import { Response } from 'express';
import { AuthenticatedRequest } from '@interfaces/AuthenticatedRequest';
import OpenAI from 'openai';

interface Input {
    application?: string;
    selectedText?: string;
}

interface ProcessInputRequest extends AuthenticatedRequest {
    body: {
        instructions: string;
        input?: Input;
    };
}

const processInput = async (
    req: ProcessInputRequest,
    res: Response
): Promise<void> => {
    const { instructions, input } = req.body;
    const { application, selectedText } = input || {};

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
        console.error(
            'Error communicating with OpenAI API:',
            error.response ? error.response.data : error.message
        );
        res.status(500).json({ message: 'Internal server error' });
    }
};

export default { processInput };
