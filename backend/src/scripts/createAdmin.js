import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import dotenv from 'dotenv';

dotenv.config();

const createAdminUser = async () => {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('[SCRIPT] Connecté à MongoDB');

    // Vérifier si l'utilisateur admin existe déjà
    const existingAdmin = await User.findOne({ username: 'admin' });
    if (existingAdmin) {
      console.log('[SCRIPT] L\'utilisateur admin existe déjà');
      return;
    }

    // Créer le mot de passe hashé
    const passwordHash = await bcrypt.hash('admin123', 10);

    // Créer l'utilisateur super-admin
    const adminUser = new User({
      username: 'admin',
      passwordHash: passwordHash,
      role: 'super-admin',
      isActive: true
    });

    await adminUser.save();
    console.log('[SCRIPT] Utilisateur super-admin créé avec succès');
    console.log('[SCRIPT] Username: admin');
    console.log('[SCRIPT] Mot de passe: admin123');
    console.log('[SCRIPT] Rôle: super-admin');

  } catch (error) {
    console.error('[SCRIPT] Erreur:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('[SCRIPT] Déconnecté de MongoDB');
  }
};

createAdminUser(); 