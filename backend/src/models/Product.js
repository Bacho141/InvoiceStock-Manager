import mongoose from 'mongoose';

const productSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true,
    trim: true,
    maxlength: 100
  },
  reference: {
    type: String,
    required: true,
    trim: true,

    maxlength: 50
  },
  description: { 
    type: String,
    unique: true,
    trim: true,
    maxlength: 500
  },
  category: { 
    type: String, 
    trim: true,
    maxlength: 50
  },
  unit: { 
    type: String, 
    default: 'pièce',
    enum: ['pièce', 'kg', 'g', 'litre', 'ml', 'm', 'cm', 'm²', 'm³', 'paquet', 'carton', 'bouteille', 'sachet']
  },
  purchasePrice: { 
    type: Number, 
    required: true,
    min: 0
  },
  sellingPrice: { 
    type: Number, 
    required: true,
    min: 0
  },
  minStockLevel: { 
    type: Number, 
    default: 0,
    min: 0
  },
  maxStockLevel: { 
    type: Number, 
    default: 0,
    min: 0
  },
  barcode: { 
    type: String, 
    trim: true,
    unique: true,
    sparse: true // Permet les valeurs null
  },
  image: { 
    type: String 
  },
  isActive: { 
    type: Boolean, 
    default: true 
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  updatedAt: { 
    type: Date, 
    default: Date.now 
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index pour optimiser les recherches
productSchema.index({ name: 1 });
productSchema.index({ category: 1 });
productSchema.index({ barcode: 1 });
productSchema.index({ isActive: 1 });
productSchema.index({ createdAt: -1 });
productSchema.index({ reference: 1 });

// Virtual pour calculer la marge
productSchema.virtual('margin').get(function() {
  if (this.purchasePrice > 0) {
    return ((this.sellingPrice - this.purchasePrice) / this.purchasePrice) * 100;
  }
  return 0;
});

// Virtual pour calculer la marge brute
productSchema.virtual('grossMargin').get(function() {
  return this.sellingPrice - this.purchasePrice;
});

// Méthode pour valider les prix
productSchema.methods.validatePrices = function() {
  if (this.sellingPrice < this.purchasePrice) {
    throw new Error('Le prix de vente ne peut pas être inférieur au prix d\'achat');
  }
  return true;
};

// Middleware pre-save pour validation
productSchema.pre('save', function(next) {
  this.validatePrices();
  next();
});

export default mongoose.model('Product', productSchema); 