import { Request, Response, NextFunction } from 'express';
import { CustomError } from '@utils/CustomError';

const errorHandler = (
    err: unknown,
    req: Request,
    res: Response,
    next: NextFunction
): void => {
    if (err instanceof CustomError) {
        res.status(err.statusCode).json({
            error: true,
            message: err.message,
        });
    } else {
        console.error('Unexpected Error:', err);
        res.status(500).json({
            error: true,
            message: 'An unexpected error occurred.',
        });
    }
};

export default errorHandler;