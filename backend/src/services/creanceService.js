import mongoose from 'mongoose';
import Client from '../models/Client.js';
import Invoice from '../models/Invoice.js';

/**
 * Service de gestion des créances
 * Contient la logique de calcul des créances, scores clients et alertes
 */
class CreanceService {
  
  /**
   * Calcule les créances en cours pour un client
   * @param {String} clientId - ID du client
   * @returns {Object} Données des créances du client
   */
  async calculateClientOutstanding(clientId) {
    try {
      const invoices = await Invoice.find({
        client: clientId,
        status: { $in: ['reste_a_payer', 'validée'] }
      }).sort({ date: -1 });

      let totalOutstanding = 0;
      let overdueAmount = 0;
      let invoicesByAge = {
        '0-30': { count: 0, amount: 0 },
        '31-60': { count: 0, amount: 0 },
        '61-90': { count: 0, amount: 0 },
        '90+': { count: 0, amount: 0 }
      };

      const now = new Date();

      invoices.forEach(invoice => {
        const outstanding = invoice.total - invoice.montantPaye;
        if (outstanding > 0) {
          totalOutstanding += outstanding;
          
          const daysDiff = Math.floor((now - invoice.date) / (1000 * 60 * 60 * 24));
          
          if (daysDiff > 30) {
            overdueAmount += outstanding;
          }

          // Classification par ancienneté
          if (daysDiff <= 30) {
            invoicesByAge['0-30'].count++;
            invoicesByAge['0-30'].amount += outstanding;
          } else if (daysDiff <= 60) {
            invoicesByAge['31-60'].count++;
            invoicesByAge['31-60'].amount += outstanding;
          } else if (daysDiff <= 90) {
            invoicesByAge['61-90'].count++;
            invoicesByAge['61-90'].amount += outstanding;
          } else {
            invoicesByAge['90+'].count++;
            invoicesByAge['90+'].amount += outstanding;
          }
        }
      });

      return {
        totalOutstanding,
        overdueAmount,
        invoicesByAge,
        totalInvoices: invoices.length
      };
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur calcul créances client:', error);
      throw error;
    }
  }

  /**
   * Met à jour le score de crédit d'un client
   * @param {String} clientId - ID du client
   * @returns {Number} Nouveau score de crédit
   */
  async updateClientScore(clientId) {
    try {
      const client = await Client.findById(clientId);
      if (!client) {
        throw new Error('Client non trouvé');
      }

      const newScore = await client.calculateCreditScore();
      
      await Client.findByIdAndUpdate(clientId, {
        creditScore: newScore
      });

      console.log(`[CREANCE][SERVICE] Score client ${clientId} mis à jour: ${newScore}`);
      return newScore;
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur mise à jour score:', error);
      throw error;
    }
  }

  /**
   * Analyse les retards de paiement d'un client
   * @param {String} clientId - ID du client
   * @returns {Object} Analyse des retards
   */
  async analyzePaymentDelays(clientId) {
    try {
      const invoices = await Invoice.find({
        client: clientId,
        status: 'payee'
      }).sort({ date: -1 });

      let totalDelays = 0;
      let delayedPayments = 0;
      let onTimePayments = 0;
      const delayHistory = [];

      for (const invoice of invoices) {
        if (invoice.paymentHistory && invoice.paymentHistory.length > 0) {
          const lastPayment = invoice.paymentHistory[invoice.paymentHistory.length - 1];
          const expectedDate = new Date(invoice.date);
          expectedDate.setDate(expectedDate.getDate() + 30); // Délai standard 30j
          
          const delay = Math.max(0, (lastPayment.date - expectedDate) / (1000 * 60 * 60 * 24));
          
          if (delay > 0) {
            totalDelays += delay;
            delayedPayments++;
          } else {
            onTimePayments++;
          }

          delayHistory.push({
            invoiceNumber: invoice.number,
            dueDate: expectedDate,
            paidDate: lastPayment.date,
            delay: Math.round(delay)
          });
        }
      }

      const averageDelay = delayedPayments > 0 ? Math.round(totalDelays / delayedPayments) : 0;
      const onTimeRatio = (onTimePayments / (onTimePayments + delayedPayments)) * 100;

      return {
        averageDelay,
        delayedPayments,
        onTimePayments,
        onTimeRatio: Math.round(onTimeRatio),
        delayHistory: delayHistory.slice(0, 10) // 10 derniers
      };
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur analyse retards:', error);
      throw error;
    }
  }

  /**
   * Génère les alertes de créances
   * @returns {Array} Liste des alertes
   */
  async generateCreanceAlerts() {
    try {
      const alerts = [];

      // Clients avec créances en retard > 90 jours
      const criticalClients = await this.getCriticalClients();
      alerts.push(...criticalClients.map(client => ({
        type: 'critical_overdue',
        clientId: client._id,
        clientName: client.fullName,
        amount: client.currentOutstanding,
        days: client.maxOverdueDays,
        priority: 'high'
      })));

      // Clients dépassant la limite de crédit
      const creditLimitExceeded = await Client.find({
        currentOutstanding: { $gt: 0 },
        $expr: { $gt: ['$currentOutstanding', '$creditLimit'] },
        creditLimitAlerts: true,
        status: 'active'
      });

      alerts.push(...creditLimitExceeded.map(client => ({
        type: 'credit_limit_exceeded',
        clientId: client._id,
        clientName: client.fullName,
        currentOutstanding: client.currentOutstanding,
        creditLimit: client.creditLimit,
        priority: 'medium'
      })));

      // Clients avec score de crédit faible
      const lowScoreClients = await Client.find({
        creditScore: { $lt: 3 },
        status: 'active',
        totalRevenue: { $gt: 0 }
      });

      alerts.push(...lowScoreClients.map(client => ({
        type: 'low_credit_score',
        clientId: client._id,
        clientName: client.fullName,
        creditScore: client.creditScore,
        priority: 'low'
      })));

      return alerts.sort((a, b) => {
        const priorityOrder = { high: 3, medium: 2, low: 1 };
        return priorityOrder[b.priority] - priorityOrder[a.priority];
      });
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur génération alertes:', error);
      throw error;
    }
  }

  /**
   * Récupère les clients critiques (>90j de retard)
   * @returns {Array} Clients critiques
   */
  async getCriticalClients() {
    try {
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      const criticalInvoices = await Invoice.aggregate([
        {
          $match: {
            date: { $lt: ninetyDaysAgo },
            status: { $in: ['reste_a_payer', 'validée'] },
            $expr: { $gt: [{ $subtract: ['$total', '$montantPaye'] }, 0] }
          }
        },
        {
          $group: {
            _id: '$client',
            outstandingAmount: {
              $sum: { $subtract: ['$total', '$montantPaye'] }
            },
            oldestInvoice: { $min: '$date' }
          }
        },
        {
          $lookup: {
            from: 'clients',
            localField: '_id',
            foreignField: '_id',
            as: 'client'
          }
        },
        {
          $unwind: '$client'
        },
        {
          $project: {
            _id: '$client._id',
            fullName: {
              $concat: ['$client.firstName', ' ', '$client.lastName']
            },
            currentOutstanding: '$outstandingAmount',
            maxOverdueDays: {
              $ceil: {
                $divide: [
                  { $subtract: [new Date(), '$oldestInvoice'] },
                  1000 * 60 * 60 * 24
                ]
              }
            }
          }
        },
        {
          $sort: { maxOverdueDays: -1 }
        }
      ]);

      return criticalInvoices;
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur clients critiques:', error);
      throw error;
    }
  }

  /**
   * Met à jour les métriques de tous les clients
   * @returns {Object} Résumé de la mise à jour
   */
  async updateAllClientMetrics() {
    try {
      const clients = await Client.find({ status: 'active' });
      let updated = 0;
      let errors = 0;

      for (const client of clients) {
        try {
          // Calcul des créances
          const outstandingData = await this.calculateClientOutstanding(client._id);
          
          // Calcul des métriques via agrégation
          const metrics = await Invoice.aggregate([
            { $match: { client: client._id } },
            {
              $group: {
                _id: null,
                totalRevenue: { $sum: '$total' },
                invoiceCount: { $sum: 1 },
                lastInvoiceDate: { $max: '$date' }
              }
            }
          ]);

          const clientMetrics = metrics[0] || {
            totalRevenue: 0,
            invoiceCount: 0,
            lastInvoiceDate: null
          };

          // Calcul délai moyen de paiement
          const averageDelay = await client.calculateAveragePaymentDelay();

          // Mise à jour du client
          await Client.findByIdAndUpdate(client._id, {
            totalRevenue: clientMetrics.totalRevenue,
            invoiceCount: clientMetrics.invoiceCount,
            lastInvoiceDate: clientMetrics.lastInvoiceDate,
            currentOutstanding: outstandingData.totalOutstanding,
            averagePaymentDelay: averageDelay
          });

          // Mise à jour du score
          await this.updateClientScore(client._id);
          updated++;
        } catch (err) {
          console.error(`[CREANCE][SERVICE] Erreur client ${client._id}:`, err);
          errors++;
        }
      }

      console.log(`[CREANCE][SERVICE] Métriques mises à jour: ${updated} succès, ${errors} erreurs`);
      return { updated, errors, total: clients.length };
    } catch (error) {
      console.error('[CREANCE][SERVICE] Erreur mise à jour globale:', error);
      throw error;
    }
  }
}

export default new CreanceService();