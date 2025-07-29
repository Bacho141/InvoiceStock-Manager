import mongoose from 'mongoose';
import User from '../models/User.js';
import dotenv from 'dotenv';

dotenv.config();

const fixAdminUser = async () => {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('[SCRIPT] Connecté à MongoDB');

    // Chercher l'utilisateur admin existant
    const existingAdmin = await User.findOne({ username: 'admin' });
    
    if (existingAdmin) {
      console.log('[SCRIPT] Utilisateur admin trouvé:', existingAdmin.username, 'Rôle actuel:', existingAdmin.role);
      
      // Vérifier si le rôle doit être corrigé
      if (existingAdmin.role !== 'super-admin') {
        console.log('[SCRIPT] Correction du rôle de super-admin...');
        existingAdmin.role = 'super-admin';
        await existingAdmin.save();
        console.log('[SCRIPT] Rôle corrigé vers super-admin');
      } else {
        console.log('[SCRIPT] Rôle déjà correct (super-admin)');
      }
      
      // S'assurer que assignedStores existe
      if (!existingAdmin.assignedStores) {
        console.log('[SCRIPT] Initialisation de assignedStores...');
        existingAdmin.assignedStores = [];
        await existingAdmin.save();
        console.log('[SCRIPT] assignedStores initialisé');
      }
      
      console.log('[SCRIPT] Utilisateur admin configuré correctement');
      console.log('[SCRIPT] Username: admin');
      console.log('[SCRIPT] Mot de passe: admin123');
      console.log('[SCRIPT] Rôle: super-admin');
      console.log('[SCRIPT] Magasins assignés:', existingAdmin.assignedStores.length);
      
    } else {
      console.log('[SCRIPT] Aucun utilisateur admin trouvé');
      console.log('[SCRIPT] Veuillez d\'abord créer un utilisateur admin');
    }

  } catch (error) {
    console.error('[SCRIPT] Erreur:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('[SCRIPT] Déconnecté de MongoDB');
  }
};

fixAdminUser(); 