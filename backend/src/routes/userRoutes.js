import express from 'express';
import { createUser, getUsers, updateUser, activateUser, revealPassword } from '../controllers/userController.js';
import { verifyToken, requireRole } from '../middleware/authMiddleware.js';

const router = express.Router();

// Route de création d'utilisateur (super-admin uniquement)
router.post('/', verifyToken, requireRole('super-admin'), createUser);
// Route de liste des utilisateurs (super-admin uniquement)
router.get('/', verifyToken, requireRole('super-admin'), getUsers);
// Route de modification d'utilisateur (super-admin uniquement)
router.put('/:id', verifyToken, requireRole('super-admin'), updateUser);
// Route d'activation/désactivation d'utilisateur (super-admin uniquement)
router.patch('/:id/activate', verifyToken, requireRole('super-admin'), activateUser);

// Route pour révéler/modifier le mot de passe (super-admin uniquement)
router.post('/:id/reveal-password', verifyToken, requireRole('super-admin'), revealPassword);

export default router; 