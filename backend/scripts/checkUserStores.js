import mongoose from 'mongoose';
import User from '../src/models/User.js';
import Store from '../src/models/Store.js';

// Configuration de la base de données
const MONGODB_URI = 'mongodb://localhost:27017/invoicestock';

async function checkUserStores() {
  try {
    console.log('[SCRIPT][checkUserStores] Connexion à MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('[SCRIPT][checkUserStores] Connexion réussie');

    // Récupérer l'utilisateur admin
    const admin = await User.findOne({ username: 'admin' });
    if (!admin) {
      console.error('[SCRIPT][checkUserStores] Utilisateur admin non trouvé');
      return;
    }

    console.log('\n=== UTILISATEUR ADMIN ===');
    console.log('ID:', admin._id);
    console.log('Username:', admin.username);
    console.log('Role:', admin.role);
    console.log('Magasins assignés:', admin.assignedStores);

    // Récupérer tous les magasins
    const allStores = await Store.find({});
    console.log('\n=== TOUS LES MAGASINS ===');
    allStores.forEach((store, index) => {
      console.log(`${index + 1}. ${store.name} (ID: ${store._id})`);
    });

    // Vérifier si les magasins sont assignés à l'admin
    if (admin.assignedStores && admin.assignedStores.length > 0) {
      console.log('\n=== MAGASINS ASSIGNÉS À L\'ADMIN ===');
      for (const storeId of admin.assignedStores) {
        const store = await Store.findById(storeId);
        if (store) {
          console.log(`- ${store.name} (ID: ${store._id})`);
        } else {
          console.log(`- Magasin non trouvé (ID: ${storeId})`);
        }
      }
    } else {
      console.log('\n❌ Aucun magasin assigné à l\'admin');
    }

    console.log('\n[SCRIPT][checkUserStores] Script terminé');

  } catch (error) {
    console.error('[SCRIPT][checkUserStores] Erreur:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('[SCRIPT][checkUserStores] Connexion fermée');
  }
}

// Exécuter le script
checkUserStores(); 