import { Response, NextFunction } from 'express';
import jwt, { JwtPayload } from 'jsonwebtoken';
import { AuthenticatedRequest } from '@interfaces/AuthenticatedRequest';
import { CustomError } from '@utils/CustomError';

const auth = (
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
): void => {
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
        throw new CustomError('Access token missing', 401);
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as
            | string
            | JwtPayload;
        req.user = decoded;
        next();
    } catch (err) {
        throw new CustomError('Invalid access token', 403);
    }
};

export default auth;