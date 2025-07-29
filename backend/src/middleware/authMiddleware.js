import jwt from 'jsonwebtoken';
import Session from '../models/Session.js';

export const verifyToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) {
    console.log('[AUTH][MIDDLEWARE] Token manquant');
    return res.status(401).json({ message: 'Token manquant.' });
  }
  
  try {
    // Vérification cryptographique du token
    const user = jwt.verify(token, process.env.JWT_SECRET);
    
    // Vérification de la session active en base
    const session = await Session.findOne({ 
      token, 
      isActive: true,
      expiresAt: { $gt: new Date() }
    });
    
    if (!session) {
      console.log('[AUTH][MIDDLEWARE] Session inactive ou expirée');
      return res.status(401).json({ message: 'Session inactive ou expirée.' });
    }
    
    // Mise à jour de l'activité de la session
    await session.updateActivity();
    
    // Ajouter les magasins assignés au user si pas déjà présents
    if (!user.assignedStores) {
      user.assignedStores = [];
    }
    // S'assurer que req.user._id est bien présent (pour Mongoose)
    user._id = user.userId;
    req.user = user;
    req.session = session;
    console.log(`[AUTH][MIDDLEWARE] Token et session valides pour ${user.username} (${user.role})`);
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      console.log('[AUTH][MIDDLEWARE] Token expiré');
      return res.status(401).json({ message: 'Token expiré.' });
    } else if (err.name === 'JsonWebTokenError') {
      console.log('[AUTH][MIDDLEWARE] Token invalide');
      return res.status(403).json({ message: 'Token invalide.' });
    } else {
      console.error('[AUTH][MIDDLEWARE] Erreur de vérification:', err.message);
      return res.status(500).json({ message: 'Erreur de vérification du token.' });
    }
  }
};

export const requireRole = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    console.log(`[AUTH][MIDDLEWARE] Accès refusé pour le rôle : ${req.user ? req.user.role : 'inconnu'}`);
    return res.status(403).json({ message: 'Accès refusé.' });
  }
  console.log(`[AUTH][MIDDLEWARE] Accès autorisé pour le rôle : ${req.user.role}`);
  next();
}; 