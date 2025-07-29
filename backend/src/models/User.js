import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  username: { 
    type: String, 
    required: true, 
    unique: true 
  },
  passwordHash: { 
    type: String, 
    required: true 
  },
  tempPassword: { // NOUVEAU - Mot de passe temporaire en clair
    type: String,
    default: null
  },
  role: { 
    type: String, 
    enum: ['super-admin', 'gestionnaire', 'caissier'], // MODIFIÉ
    required: true 
  },
  assignedStores: [{ // NOUVEAU
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Store'
  }],
  isActive: { 
    type: Boolean, 
    default: true 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

// Index pour les performances
userSchema.index({ role: 1 });
userSchema.index({ assignedStores: 1 });
userSchema.index({ isActive: 1 });

const User = mongoose.model('User', userSchema);
export default User; 