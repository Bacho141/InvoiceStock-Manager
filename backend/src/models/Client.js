import mongoose from 'mongoose';

const communicationHistorySchema = new mongoose.Schema({
  date: { type: Date, default: Date.now },
  type: { type: String, enum: ['email', 'phone', 'meeting', 'other'], required: true },
  subject: { type: String, trim: true },
  content: { type: String, trim: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
}, { _id: false });

const clientSchema = new mongoose.Schema({
  // Informations de base (existantes)
  firstName: {
    type: String,
    required: true,
    trim: true,
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
  },
  phone: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    index: true,
  },
  email: {
    type: String,
    unique: true,
    sparse: true,
    trim: true,
  },
  address: {
    type: String,
    trim: true,
  },
  
  // Informations étendues
  company: {
    type: String,
    trim: true,
  },
  customerType: {
    type: String,
    enum: ['particulier', 'entreprise'],
    default: 'particulier',
  },
  city: {
    type: String,
    trim: true,
  },
  region: {
    type: String,
    trim: true,
  },
  
  // Configuration commerciale
  assignedStore: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Store',
  },
  creditLimit: {
    type: Number,
    default: 0,
    min: 0,
  },
  paymentTerms: {
    type: Number,
    default: 30, // jours
    min: 0,
  },
  category: {
    type: String,
    enum: ['grossiste', 'detaillant', 'particulier'],
    default: 'particulier',
  },
  priority: {
    type: String,
    enum: ['bas', 'normal', 'haut'],
    default: 'normal',
  },
  assignedSalesperson: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  preferredPaymentMethod: {
    type: String,
    enum: ['especes', 'carte', 'virement', 'mobile_money', 'autre'],
    default: 'especes',
  },
  
  // Alertes et notifications
  alertsEnabled: {
    type: Boolean,
    default: true,
  },
  creditLimitAlerts: {
    type: Boolean,
    default: true,
  },
  emailInvoices: {
    type: Boolean,
    default: false,
  },
  
  // Métriques calculées (mise à jour automatique)
  totalRevenue: {
    type: Number,
    default: 0,
    min: 0,
  },
  invoiceCount: {
    type: Number,
    default: 0,
    min: 0,
  },
  lastInvoiceDate: {
    type: Date,
  },
  averagePaymentDelay: {
    type: Number,
    default: 0,
    min: 0,
  },
  creditScore: {
    type: Number,
    min: 0,
    max: 10,
    default: 5,
  },
  currentOutstanding: {
    type: Number,
    default: 0,
    min: 0,
  },
  
  // Notes et communications
  notes: {
    type: String,
    trim: true,
  },
  communicationHistory: [communicationHistorySchema],
  
  // Statut
  status: {
    type: String,
    enum: ['active', 'inactive', 'blocked'],
    default: 'active',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  
  // Historique des achats (existant)
  purchaseHistory: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Invoice',
  }],
}, {
  timestamps: true,
});

// Index pour améliorer les performances
clientSchema.index({ assignedStore: 1 });
clientSchema.index({ status: 1 });
clientSchema.index({ creditScore: -1 });
clientSchema.index({ totalRevenue: -1 });
clientSchema.index({ currentOutstanding: -1 });
clientSchema.index({ 'communicationHistory.date': -1 });

// Méthode virtuelle pour le nom complet
clientSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`.trim();
});

// Méthode pour calculer le délai de paiement moyen
clientSchema.methods.calculateAveragePaymentDelay = async function() {
  const Invoice = mongoose.model('Invoice');
  const invoices = await Invoice.find({ 
    client: this._id, 
    status: 'payee' 
  }).populate('paymentHistory');
  
  if (invoices.length === 0) return 0;
  
  let totalDelay = 0;
  let paidInvoices = 0;
  
  invoices.forEach(invoice => {
    if (invoice.paymentHistory && invoice.paymentHistory.length > 0) {
      const lastPayment = invoice.paymentHistory[invoice.paymentHistory.length - 1];
      const delay = Math.max(0, (lastPayment.date - invoice.date) / (1000 * 60 * 60 * 24));
      totalDelay += delay;
      paidInvoices++;
    }
  });
  
  return paidInvoices > 0 ? Math.round(totalDelay / paidInvoices) : 0;
};

// Méthode pour calculer le score de crédit
clientSchema.methods.calculateCreditScore = async function() {
  const Invoice = mongoose.model('Invoice');
  const invoices = await Invoice.find({ client: this._id });
  
  if (invoices.length === 0) return 5; // Score neutre par défaut
  
  let score = 5; // Score de base
  
  // Facteur 1: Historique de paiement (40%)
  const paidOnTime = invoices.filter(inv => {
    if (inv.status === 'payee' && inv.paymentHistory?.length > 0) {
      const lastPayment = inv.paymentHistory[inv.paymentHistory.length - 1];
      const delay = (lastPayment.date - inv.date) / (1000 * 60 * 60 * 24);
      return delay <= this.paymentTerms;
    }
    return false;
  }).length;
  
  const paymentRatio = invoices.length > 0 ? paidOnTime / invoices.length : 0;
  score += (paymentRatio - 0.5) * 4; // +/- 2 points
  
  // Facteur 2: Ancienneté relation (20%)
  const relationAge = (Date.now() - this.createdAt) / (1000 * 60 * 60 * 24 * 365); // années
  if (relationAge > 2) score += 1;
  if (relationAge > 5) score += 0.5;
  
  // Facteur 3: Volume d'affaires (20%)
  if (this.totalRevenue > 100000) score += 1;
  if (this.totalRevenue > 500000) score += 0.5;
  
  // Facteur 4: Créances en cours (20%)
  if (this.currentOutstanding === 0) {
    score += 1;
  } else if (this.currentOutstanding > this.creditLimit * 0.8) {
    score -= 1;
  }
  
  return Math.max(0, Math.min(10, Math.round(score * 10) / 10));
};

export default mongoose.model('Client', clientSchema); 