import mongoose from 'mongoose';
import Client from '../models/Client.js';
import Invoice from '../models/Invoice.js';
import creanceService from '../services/creanceService.js';

/**
 * Contrôleur pour les analytics clients et créances
 * Implémente les 6 endpoints définis dans le plan Sprint 1
 */

// Dashboard métriques
export const getDashboardMetrics = async (req, res) => {
  try {
    console.log('[CLIENT][ANALYTICS] Récupération métriques dashboard');

    // Métriques de base
    const totalClients = await Client.countDocuments({ status: 'active' });
    const totalInvoices = await Invoice.countDocuments();
    
    // Calcul CA du mois
    const currentMonth = new Date();
    currentMonth.setDate(1);
    currentMonth.setHours(0, 0, 0, 0);
    
    const monthlyRevenue = await Invoice.aggregate([
      {
        $match: {
          date: { $gte: currentMonth },
          status: { $ne: 'annulee' }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$total' }
        }
      }
    ]);

    // Créances totales et en retard
    const creancesData = await Invoice.aggregate([
      {
        $match: {
          status: { $in: ['reste_a_payer', 'validée'] },
          $expr: { $gt: [{ $subtract: ['$total', '$montantPaye'] }, 0] }
        }
      },
      {
        $group: {
          _id: null,
          totalCreances: { $sum: { $subtract: ['$total', '$montantPaye'] } },
          count: { $sum: 1 }
        }
      }
    ]);

    // Créances en retard (>30 jours)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const overdueData = await Invoice.aggregate([
      {
        $match: {
          date: { $lt: thirtyDaysAgo },
          status: { $in: ['reste_a_payer', 'validée'] },
          $expr: { $gt: [{ $subtract: ['$total', '$montantPaye'] }, 0] }
        }
      },
      {
        $group: {
          _id: null,
          overdueAmount: { $sum: { $subtract: ['$total', '$montantPaye'] } },
          overdueCount: { $sum: 1 }
        }
      }
    ]);

    // Taux de recouvrement
    const paidInvoices = await Invoice.countDocuments({ status: 'payee' });
    const recoveryRate = totalInvoices > 0 ? ((paidInvoices / totalInvoices) * 100).toFixed(1) : 0;

    const metrics = {
      totalClients,
      totalCreances: creancesData[0]?.totalCreances || 0,
      overdueAmount: overdueData[0]?.overdueAmount || 0,
      overdueCount: overdueData[0]?.overdueCount || 0,
      monthlyRevenue: monthlyRevenue[0]?.total || 0,
      recoveryRate: parseFloat(recoveryRate),
      totalInvoices
    };

    console.log('[CLIENT][ANALYTICS] Métriques calculées:', metrics);
    res.json({ success: true, data: metrics });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur métriques dashboard:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur récupération métriques',
      error: error.message 
    });
  }
};

// Top clients par CA
export const getTopClients = async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log(`[CLIENT][ANALYTICS] Récupération top ${limit} clients`);

    const topClients = await Client.find({ status: 'active' })
      .sort({ totalRevenue: -1 })
      .limit(parseInt(limit))
      .select('firstName lastName company totalRevenue invoiceCount currentOutstanding creditScore')
      .lean();

    const clientsWithMetrics = topClients.map(client => ({
      ...client,
      fullName: `${client.firstName} ${client.lastName}`.trim(),
      displayName: client.company || `${client.firstName} ${client.lastName}`.trim()
    }));

    res.json({ success: true, data: clientsWithMetrics });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur top clients:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur récupération top clients',
      error: error.message 
    });
  }
};

// Analyse créances par ancienneté
export const getCreancesAnalysis = async (req, res) => {
  try {
    console.log('[CLIENT][ANALYTICS] Analyse créances par ancienneté');

    const now = new Date();
    const analysis = {
      '0-30': { count: 0, amount: 0 },
      '31-60': { count: 0, amount: 0 },
      '61-90': { count: 0, amount: 0 },
      '90+': { count: 0, amount: 0 }
    };

    const creances = await Invoice.aggregate([
      {
        $match: {
          status: { $in: ['reste_a_payer', 'validée'] },
          $expr: { $gt: [{ $subtract: ['$total', '$montantPaye'] }, 0] }
        }
      },
      {
        $project: {
          outstanding: { $subtract: ['$total', '$montantPaye'] },
          daysDiff: {
            $ceil: {
              $divide: [
                { $subtract: [now, '$date'] },
                1000 * 60 * 60 * 24
              ]
            }
          }
        }
      }
    ]);

    creances.forEach(creance => {
      const { outstanding, daysDiff } = creance;
      
      if (daysDiff <= 30) {
        analysis['0-30'].count++;
        analysis['0-30'].amount += outstanding;
      } else if (daysDiff <= 60) {
        analysis['31-60'].count++;
        analysis['31-60'].amount += outstanding;
      } else if (daysDiff <= 90) {
        analysis['61-90'].count++;
        analysis['61-90'].amount += outstanding;
      } else {
        analysis['90+'].count++;
        analysis['90+'].amount += outstanding;
      }
    });

    // Calcul des pourcentages
    const totalAmount = Object.values(analysis).reduce((sum, item) => sum + item.amount, 0);
    
    Object.keys(analysis).forEach(key => {
      analysis[key].percentage = totalAmount > 0 
        ? ((analysis[key].amount / totalAmount) * 100).toFixed(1)
        : 0;
    });

    res.json({ success: true, data: { analysis, totalAmount } });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur analyse créances:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur analyse créances',
      error: error.message 
    });
  }
};

// Statistiques par client
export const getClientStats = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`[CLIENT][ANALYTICS] Statistiques client ${id}`);

    const client = await Client.findById(id);
    if (!client) {
      return res.status(404).json({ 
        success: false, 
        message: 'Client non trouvé' 
      });
    }

    // Calcul des créances
    const outstandingData = await creanceService.calculateClientOutstanding(id);
    
    // Analyse des retards
    const delayAnalysis = await creanceService.analyzePaymentDelays(id);
    
    // Évolution des factures (6 derniers mois)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const monthlyInvoices = await Invoice.aggregate([
      {
        $match: {
          client: client._id,
          date: { $gte: sixMonthsAgo }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' }
          },
          count: { $sum: 1 },
          amount: { $sum: '$total' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]);

    const stats = {
      client: {
        id: client._id,
        fullName: `${client.firstName} ${client.lastName}`.trim(),
        company: client.company,
        creditScore: client.creditScore,
        totalRevenue: client.totalRevenue,
        invoiceCount: client.invoiceCount
      },
      outstanding: outstandingData,
      paymentAnalysis: delayAnalysis,
      monthlyEvolution: monthlyInvoices
    };

    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur stats client:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur statistiques client',
      error: error.message 
    });
  }
};

// Clients en retard
export const getOverdueClients = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    console.log(`[CLIENT][ANALYTICS] Clients en retard > ${days} jours`);

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(days));

    const overdueClients = await Invoice.aggregate([
      {
        $match: {
          date: { $lt: cutoffDate },
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
          invoiceCount: { $sum: 1 },
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
          company: '$client.company',
          phone: '$client.phone',
          email: '$client.email',
          creditScore: '$client.creditScore',
          outstandingAmount: 1,
          invoiceCount: 1,
          overdueDays: {
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
        $sort: { overdueDays: -1 }
      }
    ]);

    res.json({ success: true, data: overdueClients });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur clients en retard:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur récupération clients en retard',
      error: error.message 
    });
  }
};

// Évolution financière client
export const getClientEvolution = async (req, res) => {
  try {
    const { id } = req.params;
    const { months = 12 } = req.query;
    console.log(`[CLIENT][ANALYTICS] Évolution client ${id} sur ${months} mois`);

    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - parseInt(months));

    const evolution = await Invoice.aggregate([
      {
        $match: {
          client: mongoose.Types.ObjectId(id),
          date: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' }
          },
          invoiceCount: { $sum: 1 },
          totalAmount: { $sum: '$total' },
          paidAmount: { $sum: '$montantPaye' },
          outstandingAmount: {
            $sum: { $subtract: ['$total', '$montantPaye'] }
          }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1 }
      }
    ]);

    // Formatage des données pour les graphiques
    const formattedEvolution = evolution.map(item => ({
      period: `${item._id.year}-${item._id.month.toString().padStart(2, '0')}`,
      year: item._id.year,
      month: item._id.month,
      invoiceCount: item.invoiceCount,
      totalAmount: item.totalAmount,
      paidAmount: item.paidAmount,
      outstandingAmount: item.outstandingAmount
    }));

    res.json({ success: true, data: formattedEvolution });
  } catch (error) {
    console.error('[CLIENT][ANALYTICS] Erreur évolution client:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur évolution financière client',
      error: error.message 
    });
  }
};