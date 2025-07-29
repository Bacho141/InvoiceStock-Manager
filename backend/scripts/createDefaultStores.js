import mongoose from 'mongoose';
import Store from '../src/models/Store.js';
import User from '../src/models/User.js';

// Configuration de la base de données
const MONGODB_URI = 'mongodb://localhost:27017/invoicestock';
const SUPER_ADMIN_ID = '68669c12b28d3892c782053e';

async function createDefaultStores() {
  try {
    console.log('[SCRIPT][createDefaultStores] Connexion à MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('[SCRIPT][createDefaultStores] Connexion réussie');

    // Supprimer les magasins existants pour éviter les doublons
    await Store.deleteMany({});
    console.log('[SCRIPT][createDefaultStores] Anciens magasins supprimés');

    // Créer les deux magasins par défaut avec createdBy
    const stores = [
      {
        name: 'Magasin Principal',
        address: '123 Rue de la Commerce, Ville Principale',
        phone: '+33 1 23 45 67 89',
        email: 'contact@magasin-principal.fr',
        isActive: true,
        createdBy: SUPER_ADMIN_ID,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        name: 'Magasin Secondaire',
        address: '456 Avenue des Affaires, Ville Secondaire',
        phone: '+33 1 98 76 54 32',
        email: 'contact@magasin-secondaire.fr',
        isActive: true,
        createdBy: SUPER_ADMIN_ID,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];

    console.log('[SCRIPT][createDefaultStores] Création des magasins...');
    const createdStores = await Store.insertMany(stores);
    console.log('[SCRIPT][createDefaultStores] Magasins créés:', createdStores.map(s => s.name));

    // Récupérer l'utilisateur super-admin
    const superAdmin = await User.findById(SUPER_ADMIN_ID);
    if (!superAdmin) {
      console.error('[SCRIPT][createDefaultStores] Utilisateur admin non trouvé');
      return;
    }

    // Assigner les magasins à l'utilisateur super-admin
    const storeIds = createdStores.map(store => store._id);
    superAdmin.assignedStores = storeIds;
    await superAdmin.save();

    console.log('[SCRIPT][createDefaultStores] Magasins assignés à l\'utilisateur admin');
    console.log('[SCRIPT][createDefaultStores] Magasins assignés:', storeIds);

    // Afficher les informations finales
    console.log('\n=== MAGASINS CRÉÉS ===');
    createdStores.forEach((store, index) => {
      console.log(`${index + 1}. ${store.name}`);
      console.log(`   Adresse: ${store.address}`);
      console.log(`   Téléphone: ${store.phone}`);
      console.log(`   Email: ${store.email}`);
      console.log(`   ID: ${store._id}`);
      console.log('');
    });

    console.log('[SCRIPT][createDefaultStores] Script terminé avec succès');

  } catch (error) {
    console.error('[SCRIPT][createDefaultStores] Erreur:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('[SCRIPT][createDefaultStores] Connexion fermée');
  }
}

// Exécuter le script
createDefaultStores(); 