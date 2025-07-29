import User from '../models/User.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import Session from '../models/Session.js';

export const login = async (req, res) => {
  console.log('[AUTH][LOGIN] Tentative de connexion pour', req.body.username);
  
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      console.log('[AUTH][LOGIN] Champs manquants');
      return res.status(400).json({ message: 'Nom d\'utilisateur et mot de passe requis.' });
    }

    const user = await User.findOne({ username, isActive: true })
      .populate('assignedStores', 'name isActive'); // NOUVEAU

    if (!user) {
      console.log(`[AUTH][LOGIN] Utilisateur non trouvé : ${username}`);
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    if (!user.isActive) {
      console.log(`[AUTH][LOGIN] Utilisateur inactif : ${username}`);
      return res.status(403).json({ message: 'Compte désactivé.' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      console.log(`[AUTH][LOGIN] Mot de passe incorrect pour : ${username}`);
      return res.status(401).json({ message: 'Identifiants invalides.' });
    }

    // Vérifier que l'utilisateur a au moins un magasin assigné (sauf pour super-admin)
    if (user.role !== 'super-admin' && (!user.assignedStores || user.assignedStores.length === 0)) {
      console.log('[AUTH][LOGIN] Échec - aucun magasin assigné');
      return res.status(403).json({ 
        message: 'Aucun magasin assigné à cet utilisateur.' 
      });
    }

    // Générer le JWT avec les magasins assignés
    const expiresIn = '8h';
    const token = jwt.sign(
      { 
        userId: user._id, 
        username: user.username, 
        role: user.role,
        assignedStores: user.assignedStores ? user.assignedStores.map(s => s._id) : [] // Gestion du cas undefined
      },
      process.env.JWT_SECRET,
      { expiresIn }
    );

    // Création de la session
    const userAgent = req.headers['user-agent'] || '';
    const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress || '';
    const decoded = jwt.decode(token);
    const expiresAt = new Date(decoded.exp * 1000);
    
    await Session.create({
      userId: user._id,
      token,
      deviceInfo: {
        userAgent,
        ip,
        platform: req.body.platform || ''
      },
      expiresAt
    });

    console.log(`[AUTH][LOGIN] Connexion réussie pour : ${username} (${user.role})`);
    
    res.json({ 
      token, 
      user: { 
        id: user._id,
        username: user.username, 
        role: user.role,
        assignedStores: user.assignedStores || [] // Gestion du cas undefined
      } 
    });
  } catch (error) {
    console.error('[AUTH][LOGIN] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
};

export const logout = async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'Token manquant.' });
    }
    // Désactiver la session
    const session = await Session.findOne({ token, isActive: true });
    if (!session) {
      return res.status(400).json({ message: 'Session non trouvée ou déjà déconnectée.' });
    }
    session.isActive = false;
    await session.save();
    return res.json({ message: 'Déconnexion réussie.' });
  } catch (error) {
    console.error('[AUTH][LOGOUT] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
};

export const verifySession = async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({ valid: false, message: 'Token manquant.' });
    }
    
    // Vérification cryptographique du token
    const user = jwt.verify(token, process.env.JWT_SECRET);
    
    // Vérification de la session active en base
    const session = await Session.findOne({ 
      token, 
      isActive: true,
      expiresAt: { $gt: new Date() }
    });
    
    if (!session) {
      return res.status(401).json({ valid: false, message: 'Session inactive ou expirée.' });
    }
    
    return res.json({ 
      valid: true, 
      user: { username: user.username, role: user.role },
      sessionInfo: {
        lastActivity: session.lastActivity,
        expiresAt: session.expiresAt,
        deviceInfo: session.deviceInfo
      }
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ valid: false, message: 'Token expiré.' });
    } else if (error.name === 'JsonWebTokenError') {
      return res.status(403).json({ valid: false, message: 'Token invalide.' });
    } else {
      console.error('[AUTH][VERIFY] Erreur serveur :', error.message);
      return res.status(500).json({ valid: false, message: 'Erreur serveur.' });
    }
  }
};

export const getSessionInfo = async (req, res) => {
  try {
    // req.session est disponible grâce au middleware verifyToken
    const session = req.session;
    const user = req.user;
    
    return res.json({
      user: { username: user.username, role: user.role },
      session: {
        lastActivity: session.lastActivity,
        expiresAt: session.expiresAt,
        deviceInfo: session.deviceInfo,
        createdAt: session.createdAt
      }
    });
  } catch (error) {
    console.error('[AUTH][SESSION_INFO] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
}; 