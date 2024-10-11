import 'module-alias/register';
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import path from 'path';
import routes from '@routes/index';
import errorHandler from '@middleware/errorHandler';

const app = express();

app.use(express.json());

app.use(express.static(path.join(__dirname, 'public')));

app.use('/', routes);

app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
