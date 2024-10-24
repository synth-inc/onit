import express from 'express';
import chatController from '@controllers/chatController';
import auth from '@middleware/auth';

const router = express.Router();

// POST /process
router.post('/process', auth, chatController.upload.array('file'), chatController.processInput);

export default router;
