import mongoose from 'mongoose';
import User from '../src/models/User.js';

// Configuration de la base de données
const MONGODB_URI = 'mongodb://localhost:27017/invoicestock';

async function listUsers() {
  try {
    console.log('[SCRIPT][listUsers] Connexion à MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('[SCRIPT][listUsers] Connexion réussie');

    // Récupérer tous les utilisateurs
    const users = await User.find({});
    
    if (users.length === 0) {
      console.log('[SCRIPT][listUsers] Aucun utilisateur trouvé dans la base de données');
    } else {
      console.log('\n=== UTILISATEURS DANS LA BASE ===');
      users.forEach((user, index) => {
        console.log(`${index + 1}. Username: ${user.username}`);
        console.log(`   ID: ${user._id}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Magasins assignés: ${user.assignedStores ? user.assignedStores.length : 0}`);
        console.log('');
      });
    }

    console.log('[SCRIPT][listUsers] Script terminé');

  } catch (error) {
    console.error('[SCRIPT][listUsers] Erreur:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('[SCRIPT][listUsers] Connexion fermée');
  }
}

// Exécuter le script
listUsers(); 