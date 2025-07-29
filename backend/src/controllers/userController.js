import User from '../models/User.js';
import bcrypt from 'bcrypt';
import { generateRobustPassword } from '../utils/passwordGenerator.js';

export const createUser = async (req, res) => {
  console.log('[USER][POST] Création d\'utilisateur - Données reçues:', req.body);
  try {
    const { username, role } = req.body;
    
    // Validation des champs
    if (!username || !role) {
      console.log('[USER][POST] Champs manquants:', { username: !!username, role: !!role });
      return res.status(400).json({ message: 'Nom d\'utilisateur et rôle sont obligatoires.' });
    }
    
    // Validation du rôle
    const validRoles = ['super-admin', 'gestionnaire', 'caissier'];
    if (!validRoles.includes(role)) {
      console.log('[USER][POST] Rôle invalide:', role);
      return res.status(400).json({ 
        message: `Rôle invalide. Rôles autorisés: ${validRoles.join(', ')}` 
      });
    }
    
    // Vérifier unicité du username
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      console.log('[USER][POST] Username déjà utilisé:', username);
      return res.status(409).json({ message: 'Nom d\'utilisateur déjà utilisé.' });
    }
    
    // Générer un mot de passe robuste
    const tempPassword = generateRobustPassword();
    const passwordHash = await bcrypt.hash(tempPassword, 10);
    console.log('[USER][POST] Mot de passe généré pour:', username);
    
    // Créer l'utilisateur
    const user = new User({ 
      username, 
      passwordHash, 
      tempPassword, // Stocker le mot de passe temporaire
      role,
      assignedStores: [], // Initialiser avec une liste vide
      isActive: true 
    });
    
    await user.save();
    console.log('[USER][POST] Utilisateur créé avec succès:', username, 'Rôle:', role);
    res.status(201).json({ 
      message: 'Utilisateur créé avec succès.',
      tempPassword: tempPassword // Retourner le mot de passe temporaire
    });
  } catch (error) {
    console.error('[USER][POST] Erreur serveur:', error.message);
    console.error('[USER][POST] Stack trace:', error.stack);
    res.status(500).json({ 
      message: 'Erreur serveur.', 
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

export const getUsers = async (req, res) => {
  console.log('[USER][GET] Récupération de la liste des utilisateurs');
  try {
    const users = await User.find({}, '-passwordHash').populate('assignedStores', 'name address isActive');
    console.log(`[USER][GET] ${users.length} utilisateur(s) trouvé(s)`);
    
    // Formater les données pour le frontend
    const formattedUsers = users.map(user => ({
      id: user._id.toString(),
      username: user.username,
      role: user.role,
      assignedStores: user.assignedStores || [],
      isActive: user.isActive,
      createdAt: user.createdAt,
      hasTempPassword: !!user.tempPassword, // Indiquer si un mot de passe temporaire existe
    }));
    
    console.log('[USER][GET] Données formatées:', JSON.stringify(formattedUsers, null, 2));
    res.json(formattedUsers);
  } catch (error) {
    console.error('[USER][GET] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
};

export const updateUser = async (req, res) => {
  const userId = req.params.id;
  const { username, role } = req.body;
  console.log(`[USER][PUT] Modification utilisateur ${userId} - Données:`, req.body);
  try {
    const user = await User.findById(userId);
    if (!user) {
      console.log(`[USER][PUT] Utilisateur non trouvé: ${userId}`);
      return res.status(404).json({ message: 'Utilisateur non trouvé.' });
    }
    if (username) user.username = username;
    if (role) user.role = role;
    await user.save();
    console.log(`[USER][PUT] Utilisateur modifié: ${userId}`);
    res.json({ message: 'Utilisateur modifié avec succès.' });
  } catch (error) {
    console.error('[USER][PUT] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
};

export const activateUser = async (req, res) => {
  const userId = req.params.id;
  const { isActive } = req.body;
  console.log(`[USER][PATCH] Activation/désactivation utilisateur ${userId} - isActive:`, isActive);
  try {
    const user = await User.findById(userId);
    if (!user) {
      console.log(`[USER][PATCH] Utilisateur non trouvé: ${userId}`);
      return res.status(404).json({ message: 'Utilisateur non trouvé.' });
    }
    user.isActive = isActive;
    await user.save();
    console.log(`[USER][PATCH] Statut modifié pour ${userId}: ${isActive}`);
    res.json({ message: `Utilisateur ${isActive ? 'activé' : 'désactivé'} avec succès.` });
  } catch (error) {
    console.error('[USER][PATCH] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
};

// NOUVELLE ROUTE : Révéler/modifier le mot de passe d'un utilisateur
export const revealPassword = async (req, res) => {
  const userId = req.params.id;
  const { adminPassword, newPassword } = req.body;
  console.log(`[USER][POST] Révélation mot de passe utilisateur ${userId}`);
  
  try {
    // Vérifier le mot de passe du super-admin
    const adminUser = await User.findById(req.user.userId);
    if (!adminUser) {
      return res.status(404).json({ message: 'Utilisateur admin non trouvé.' });
    }
    
    const isAdminPasswordValid = await bcrypt.compare(adminPassword, adminUser.passwordHash);
    if (!isAdminPasswordValid) {
      console.log('[USER][POST] Mot de passe admin incorrect');
      return res.status(401).json({ message: 'Mot de passe administrateur incorrect.' });
    }
    
    // Trouver l'utilisateur cible
    const targetUser = await User.findById(userId);
    if (!targetUser) {
      console.log(`[USER][POST] Utilisateur cible non trouvé: ${userId}`);
      return res.status(404).json({ message: 'Utilisateur non trouvé.' });
    }
    
    let tempPassword = targetUser.tempPassword;
    
    // Si un nouveau mot de passe est fourni, le générer
    if (newPassword) {
      tempPassword = newPassword;
      const passwordHash = await bcrypt.hash(newPassword, 10);
      targetUser.passwordHash = passwordHash;
      targetUser.tempPassword = newPassword;
      await targetUser.save();
      console.log(`[USER][POST] Mot de passe modifié pour ${targetUser.username}`);
    }
    
    // Si pas de mot de passe temporaire, en générer un nouveau
    if (!tempPassword) {
      tempPassword = generateRobustPassword();
      const passwordHash = await bcrypt.hash(tempPassword, 10);
      targetUser.passwordHash = passwordHash;
      targetUser.tempPassword = tempPassword;
      await targetUser.save();
      console.log(`[USER][POST] Nouveau mot de passe généré pour ${targetUser.username}`);
    }
    
    console.log(`[USER][POST] Mot de passe révélé pour ${targetUser.username}`);
    res.json({ 
      message: 'Mot de passe récupéré avec succès.',
      tempPassword: tempPassword
    });
  } catch (error) {
    console.error('[USER][POST] Erreur serveur :', error.message);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}; 