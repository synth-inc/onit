import express from 'express';
import chatController from '@controllers/chatController';
import tokenController from '@controllers/tokenController';
import auth from '@middleware/auth';

const router = express.Router();

// POST /process
router.post('/process', auth, chatController.upload.array('file'), chatController.processInput);

// GET /token/refresh
router.get('/token/refresh', tokenController.generateToken);

export default router;
