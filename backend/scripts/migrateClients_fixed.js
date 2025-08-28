import mongoose from 'mongoose';
import connectDB from '../src/config/db.js';
import Client from '../src/models/Client.js';
import Invoice from '../src/models/Invoice.js';
import creanceService from '../src/services/creanceService.js';

/**
 * Script de migration pour les clients existants
 * Met à jour les clients avec les nouvelles propriétés CRM
 */

async function migrateClients() {
  try {
    console.log('[MIGRATION] Début de la migration des clients...');
    
    await connectDB();
    
    // Récupérer tous les clients existants
    const clients = await Client.find({});
    console.log(`[MIGRATION] ${clients.length} clients trouvés`);
    
    let updated = 0;
    let errors = 0;
    
    for (const client of clients) {
      try {
        console.log(`[MIGRATION] Traitement client: ${client.firstName} ${client.lastName}`);
        
        // Calculer les métriques historiques
        const invoices = await Invoice.find({ client: client._id });
        
        let totalRevenue = 0;
        let lastInvoiceDate = null;
        
        invoices.forEach(invoice => {
          totalRevenue += invoice.total;
          if (!lastInvoiceDate || invoice.date > lastInvoiceDate) {
            lastInvoiceDate = invoice.date;
          }
        });
        
        // Calculer les créances actuelles
        const outstandingData = await creanceService.calculateClientOutstanding(client._id);
        
        // Calculer le délai moyen de paiement
        const averageDelay = await client.calculateAveragePaymentDelay();
        
        // Mettre à jour le client avec les nouvelles propriétés
        const updateData = {
          // Assurer que les nouveaux champs ont des valeurs par défaut
          customerType: client.customerType || 'particulier',
          category: client.category || 'particulier',
          priority: client.priority || 'normal',
          preferredPaymentMethod: client.preferredPaymentMethod || 'especes',
          creditLimit: client.creditLimit || 0,
          paymentTerms: client.paymentTerms || 30,
          
          // Calculer les métriques
          totalRevenue,
          invoiceCount: invoices.length,
          lastInvoiceDate,
          currentOutstanding: outstandingData.totalOutstanding,
          averagePaymentDelay: averageDelay,
          
          // Alertes par défaut
          alertsEnabled: client.alertsEnabled !== undefined ? client.alertsEnabled : true,
          creditLimitAlerts: client.creditLimitAlerts !== undefined ? client.creditLimitAlerts : true,
          emailInvoices: client.emailInvoices !== undefined ? client.emailInvoices : false,
          
          // Statut par défaut
          status: client.status || 'active',
          isActive: client.isActive !== undefined ? client.isActive : true
        };
        
        await Client.findByIdAndUpdate(client._id, updateData);
        
        // Calculer et mettre à jour le score de crédit
        try {
          const newScore = await client.calculateCreditScore();
          await Client.findByIdAndUpdate(client._id, { creditScore: newScore });
          console.log(`[MIGRATION] Client ${client.firstName} ${client.lastName} - Score: ${newScore}`);
        } catch (scoreError) {
          console.warn(`[MIGRATION] Erreur calcul score pour ${client.firstName} ${client.lastName}:`, scoreError.message);
        }
        
        updated++;
        console.log(`[MIGRATION] ✅ Client ${client.firstName} ${client.lastName} mis à jour`);
        
      } catch (error) {
        console.error(`[MIGRATION] ❌ Erreur client ${client.firstName} ${client.lastName}:`, error.message);
        errors++;
      }
    }
    
    console.log(`[MIGRATION] Migration terminée:`);
    console.log(`[MIGRATION] - Clients mis à jour: ${updated}`);
    console.log(`[MIGRATION] - Erreurs: ${errors}`);
    console.log(`[MIGRATION] - Total: ${clients.length}`);
    
    // Afficher un résumé des métriques
    console.log('\n[MIGRATION] Résumé des métriques calculées:');
    const summary = await Client.aggregate([
      {
        $group: {
          _id: null,
          totalClients: { $sum: 1 },
          totalRevenue: { $sum: '$totalRevenue' },
          totalOutstanding: { $sum: '$currentOutstanding' },
          averageScore: { $avg: '$creditScore' }
        }
      }
    ]);
    
    if (summary.length > 0) {
      const stats = summary[0];
      console.log(`[MIGRATION] - Total clients: ${stats.totalClients}`);
      console.log(`[MIGRATION] - CA total: ${stats.totalRevenue.toFixed(2)} F`);
      console.log(`[MIGRATION] - Créances totales: ${stats.totalOutstanding.toFixed(2)} F`);
      console.log(`[MIGRATION] - Score moyen: ${stats.averageScore.toFixed(1)}/10`);
    }
    
  } catch (error) {
    console.error('[MIGRATION] Erreur générale:', error);
  } finally {
    await mongoose.connection.close();
    console.log('[MIGRATION] Connexion fermée');
  }
}

// Fonction pour nettoyer/réinitialiser les métriques (utile pour les tests)
async function resetClientMetrics() {
  try {
    console.log('[MIGRATION] Réinitialisation des métriques clients...');
    
    await connectDB();
    
    await Client.updateMany({}, {
      $set: {
        totalRevenue: 0,
        invoiceCount: 0,
        currentOutstanding: 0,
        averagePaymentDelay: 0,
        creditScore: 5,
        lastInvoiceDate: null
      }
    });
    
    console.log('[MIGRATION] ✅ Métriques réinitialisées');
    
  } catch (error) {
    console.error('[MIGRATION] Erreur réinitialisation:', error);
  } finally {
    await mongoose.connection.close();
  }
}

// Exécution selon l'argument passé
const action = process.argv[2];

if (action === 'reset') {
  resetClientMetrics();
} else {
  migrateClients();
}

// Pour exporter les fonctions si nécessaire
export { migrateClients, resetClientMetrics };