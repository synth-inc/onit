import dotenv from 'dotenv';
dotenv.config();

import jwt from 'jsonwebtoken';

const token = jwt.sign({ username: 'testUser' }, process.env.JWT_SECRET as string, {
  expiresIn: '1w',
});

console.log(token);
