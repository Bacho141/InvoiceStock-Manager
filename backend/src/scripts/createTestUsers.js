import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import dotenv from 'dotenv';

dotenv.config();

const createTestUsers = async () => {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('[SCRIPT] Connecté à MongoDB');

    const users = [
      {
        username: 'caissier',
        password: 'caissier123',
        role: 'caissier'
      },
      {
        username: 'gestionnaire',
        password: 'gestionnaire123',
        role: 'gestionnaire'
      },
      {
        username: 'admin',
        password: 'admin123',
        role: 'administrateur'
      }
    ];

    for (const userData of users) {
      // Vérifier si l'utilisateur existe déjà
      const existingUser = await User.findOne({ username: userData.username });
      if (existingUser) {
        console.log(`[SCRIPT] L'utilisateur ${userData.username} existe déjà`);
        continue;
      }

      // Créer le mot de passe hashé
      const passwordHash = await bcrypt.hash(userData.password, 10);

      // Créer l'utilisateur
      const user = new User({
        username: userData.username,
        passwordHash: passwordHash,
        role: userData.role,
        isActive: true
      });

      await user.save();
      console.log(`[SCRIPT] Utilisateur ${userData.role} créé avec succès`);
      console.log(`[SCRIPT] Username: ${userData.username}`);
      console.log(`[SCRIPT] Mot de passe: ${userData.password}`);
      console.log(`[SCRIPT] Rôle: ${userData.role}`);
      console.log('---');
    }

  } catch (error) {
    console.error('[SCRIPT] Erreur:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('[SCRIPT] Déconnecté de MongoDB');
  }
};

createTestUsers(); 