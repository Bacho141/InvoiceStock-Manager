import jwt from 'jsonwebtoken';
import Session from '../models/Session.js';

export const verifyToken = async (req, res, next) => {
  console.log('[AUTH][MIDDLEWARE] Début de verifyToken');
  const authHeader = req.headers['authorization'];
  let token = authHeader && authHeader.split(' ')[1];
  
  // Si pas de token dans le header, vérifier dans les query parameters pour les accès navigateur
  if (!token && req.query.token) {
    token = req.query.token;
    console.log('[AUTH][MIDDLEWARE] Token récupéré depuis query params');
  }
  
  console.log('[AUTH][MIDDLEWARE] Token reçu (partiel): ', token ? token.substring(0, 10) + '...' : 'null');

  if (!token) {
    console.log('[AUTH][MIDDLEWARE] Token manquant');
    return res.status(401).json({ message: 'Token manquant.' });
  }
  
  try {
    console.log('[AUTH][MIDDLEWARE] Tentative de vérification du token...');
    const user = jwt.verify(token, process.env.JWT_SECRET);
    console.log('[AUTH][MIDDLEWARE] Token vérifié. User: ', user.username, ' Role: ', user.role);
    
    console.log('[AUTH][MIDDLEWARE] Vérification de la session en base...');
    const session = await Session.findOne({ 
      token, 
      isActive: true,
      expiresAt: { $gt: new Date() }
    });
    
    if (!session) {
      console.log('[AUTH][MIDDLEWARE] Session inactive ou expirée');
      return res.status(401).json({ message: 'Session inactive ou expirée.' });
    }
    console.log('[AUTH][MIDDLEWARE] Session trouvée et active.');
    
    // Mise à jour de l'activité de la session
    await session.updateActivity();
    console.log('[AUTH][MIDDLEWARE] Activité de session mise à jour.');
    
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
    console.log('[AUTH][MIDDLEWARE] Erreur dans le bloc catch:', err.name, err.message);
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