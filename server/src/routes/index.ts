import express from 'express';
import chatController from '@controllers/chatController';
import auth from '@middleware/auth';

const router = express.Router();

// POST /api/process
router.post('/process', auth, chatController.processInput);

export default router;
