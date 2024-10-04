import { Response, NextFunction } from 'express';
import jwt, { JwtPayload } from 'jsonwebtoken';
import { AuthenticatedRequest } from '@interfaces/AuthenticatedRequest';

const auth = async (
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
): Promise<void> => {
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
        res.status(401).json({ message: 'Access token missing' });
        return;
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as
            | string
            | JwtPayload;
        req.user = decoded;
        next();
    } catch (err) {
        res.status(403).json({ message: 'Invalid access token' });
    }
};

export default auth;
