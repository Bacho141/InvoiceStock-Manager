import express from 'express';
import { login, logout, verifySession, getSessionInfo } from '../controllers/authController.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/login', login);
router.post('/logout', logout);
router.get('/verify', verifySession);
router.get('/session-info', verifyToken, getSessionInfo);

export default router; 