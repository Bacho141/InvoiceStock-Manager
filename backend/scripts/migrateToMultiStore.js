import mongoose from 'mongoose';
import User from '../src/models/User.js';
import Store from '../src/models/Store.js';
import dotenv from 'dotenv';

dotenv.config();

async function migrateToMultiStore() {
  try {
    console.log('[MIGRATION] Début de la migration multi-magasins...');
    
    // Connexion à la base de données
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('[MIGRATION] Connexion à MongoDB établie');
    
    // 1. Créer le magasin principal
    console.log('[MIGRATION] Création du magasin principal...');
    
    // Trouver d'abord un utilisateur existant pour être le créateur
    const existingUser = await User.findOne({});
    if (!existingUser) {
      throw new Error('Aucun utilisateur trouvé pour créer le magasin principal');
    }
    
    const mainStore = await Store.create({
      name: 'Magasin Principal',
      address: 'Adresse principale',
      isActive: true,
      createdBy: existingUser._id // Utiliser un utilisateur existant temporairement
    });
    
    console.log('[MIGRATION] Magasin principal créé:', mainStore.name, '(ID:', mainStore._id, ')');
    
    // 2. Mettre à jour les utilisateurs existants
    console.log('[MIGRATION] Mise à jour des utilisateurs existants...');
    const users = await User.find({});
    
    for (const user of users) {
      console.log('[MIGRATION] Traitement utilisateur:', user.username);
      
      // Changer le rôle administrateur en super-admin
      if (user.role === 'administrateur') {
        user.role = 'super-admin';
        console.log('[MIGRATION] Rôle changé: administrateur -> super-admin');
      }
      
      // Assigner le magasin principal
      user.assignedStores = [mainStore._id];
      
      await user.save();
      console.log('[MIGRATION] Utilisateur mis à jour:', user.username, '- Rôle:', user.role);
    }
    
    // 3. Mettre à jour le créateur du magasin principal
    console.log('[MIGRATION] Mise à jour du créateur du magasin principal...');
    const superAdmin = await User.findOne({ role: 'super-admin' });
    if (superAdmin) {
      mainStore.createdBy = superAdmin._id;
      await mainStore.save();
      console.log('[MIGRATION] Créateur du magasin principal mis à jour:', superAdmin.username);
    } else {
      console.log('[MIGRATION] Aucun super-admin trouvé pour le magasin principal');
    }
    
    // 4. Vérification finale
    console.log('[MIGRATION] Vérification finale...');
    const finalUsers = await User.find({}).populate('assignedStores', 'name');
    const finalStores = await Store.find({});
    
    console.log('[MIGRATION] Résumé de la migration:');
    console.log('- Magasins créés:', finalStores.length);
    console.log('- Utilisateurs mis à jour:', finalUsers.length);
    
    for (const user of finalUsers) {
      console.log(`  - ${user.username} (${user.role}): ${user.assignedStores.map(s => s.name).join(', ')}`);
    }
    
    console.log('[MIGRATION] Migration terminée avec succès !');
  } catch (error) {
    console.error('[MIGRATION] Erreur:', error);
  } finally {
    await mongoose.disconnect();
    console.log('[MIGRATION] Connexion MongoDB fermée');
  }
}

// Exécuter la migration
migrateToMultiStore(); 