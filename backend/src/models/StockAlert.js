import mongoose from 'mongoose';

const stockAlertSchema = new mongoose.Schema({
  productId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Product', 
    required: true 
  },
  storeId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Store', 
    required: true 
  },
  type: { 
    type: String, 
    enum: ['LOW_STOCK', 'OUT_OF_STOCK', 'OVERSTOCK', 'EXPIRY_WARNING'], 
    required: true 
  },
  currentQuantity: { 
    type: Number, 
    required: true 
  },
  threshold: { 
    type: Number, 
    required: true 
  },
  severity: {
    type: String,
    enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
    default: 'MEDIUM'
  },
  isActive: { 
    type: Boolean, 
    default: true 
  },
  isRead: {
    type: Boolean,
    default: false
  },
  readBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  readAt: Date,
  resolvedAt: Date,
  resolvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  resolutionNotes: {
    type: String,
    trim: true,
    maxlength: 500
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index pour optimiser les recherches
stockAlertSchema.index({ productId: 1, storeId: 1, type: 1 });
stockAlertSchema.index({ storeId: 1, isActive: 1, severity: 1 });
stockAlertSchema.index({ isActive: 1, isRead: 1, createdAt: -1 });
stockAlertSchema.index({ createdAt: -1 });

// Virtual pour calculer la durée de l'alerte
stockAlertSchema.virtual('duration').get(function() {
  if (this.resolvedAt) {
    return this.resolvedAt - this.createdAt;
  }
  return Date.now() - this.createdAt;
});

// Virtual pour obtenir le message d'alerte
stockAlertSchema.virtual('message').get(function() {
  const messages = {
    'LOW_STOCK': `Stock bas pour le produit. Quantité actuelle: ${this.currentQuantity}, Seuil: ${this.threshold}`,
    'OUT_OF_STOCK': 'Produit en rupture de stock',
    'OVERSTOCK': `Stock élevé. Quantité actuelle: ${this.currentQuantity}, Seuil: ${this.threshold}`,
    'EXPIRY_WARNING': 'Produit proche de la date d\'expiration'
  };
  return messages[this.type] || 'Alerte de stock';
});

// Virtual pour obtenir la couleur selon le type
stockAlertSchema.virtual('typeColor').get(function() {
  const colorMap = {
    'LOW_STOCK': 'orange',
    'OUT_OF_STOCK': 'red',
    'OVERSTOCK': 'yellow',
    'EXPIRY_WARNING': 'purple'
  };
  return colorMap[this.type] || 'gray';
});

// Virtual pour obtenir l'icône selon le type
stockAlertSchema.virtual('typeIcon').get(function() {
  const iconMap = {
    'LOW_STOCK': 'warning',
    'OUT_OF_STOCK': 'error',
    'OVERSTOCK': 'info',
    'EXPIRY_WARNING': 'schedule'
  };
  return iconMap[this.type] || 'notifications';
});

// Méthode statique pour créer une alerte de stock bas
stockAlertSchema.statics.createLowStockAlert = function(data) {
  return new this({
    ...data,
    type: 'LOW_STOCK',
    severity: data.currentQuantity === 0 ? 'CRITICAL' : 'HIGH'
  });
};

// Méthode statique pour créer une alerte de rupture de stock
stockAlertSchema.statics.createOutOfStockAlert = function(data) {
  return new this({
    ...data,
    type: 'OUT_OF_STOCK',
    severity: 'CRITICAL'
  });
};

// Méthode statique pour créer une alerte de surstock
stockAlertSchema.statics.createOverstockAlert = function(data) {
  return new this({
    ...data,
    type: 'OVERSTOCK',
    severity: 'MEDIUM'
  });
};

// Méthode pour marquer l'alerte comme lue
stockAlertSchema.methods.markAsRead = function(userId) {
  this.isRead = true;
  this.readBy = userId;
  this.readAt = new Date();
  return this;
};

// Méthode pour résoudre l'alerte
stockAlertSchema.methods.resolve = function(userId, notes = '') {
  this.isActive = false;
  this.resolvedAt = new Date();
  this.resolvedBy = userId;
  this.resolutionNotes = notes;
  return this;
};

// Méthode pour réactiver l'alerte
stockAlertSchema.methods.reactivate = function() {
  this.isActive = true;
  this.isRead = false;
  this.readBy = null;
  this.readAt = null;
  this.resolvedAt = null;
  this.resolvedBy = null;
  this.resolutionNotes = '';
  return this;
};

// Middleware pre-save pour définir la sévérité automatiquement
stockAlertSchema.pre('save', function(next) {
  if (this.type === 'LOW_STOCK' && this.currentQuantity === 0) {
    this.severity = 'CRITICAL';
  } else if (this.type === 'OUT_OF_STOCK') {
    this.severity = 'CRITICAL';
  } else if (this.type === 'LOW_STOCK' && this.currentQuantity <= this.threshold * 0.2) {
    this.severity = 'HIGH';
  } else if (this.type === 'LOW_STOCK') {
    this.severity = 'MEDIUM';
  } else if (this.type === 'OVERSTOCK') {
    this.severity = 'LOW';
  }
  next();
});

export default mongoose.model('StockAlert', stockAlertSchema); 