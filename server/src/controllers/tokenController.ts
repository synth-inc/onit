import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { CustomError } from '@utils/CustomError';

const generateToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        if (!process.env.JWT_SECRET) {
            throw new CustomError('JWT_SECRET is not configured', 500);
        }

        const token = jwt.sign(
            { username: 'testUser' }, 
            process.env.JWT_SECRET, 
            { expiresIn: '30d' }
        );

        res.json({ token });
    } catch (error: any) {
        next(error);
    }
};

export default { generateToken };