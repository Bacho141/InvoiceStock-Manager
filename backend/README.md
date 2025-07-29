# 🏪 **Backend InvoiceStock Manager - Multi-Magasins**

---

## 🆕 **Principales évolutions récentes (2024)**

- **Ajustement de stock après création de produit** : Après l'ajout d'un produit, le frontend propose automatiquement d'initialiser le stock via un appel à `/api/stock/adjust` (sauf si le magasin "Tous" est sélectionné, ce qui est interdit pour les ajustements).
- **Suppression logique des produits** : La suppression d'un produit ne le retire pas de la base, mais passe `isActive` à `false`. Les endpoints et le frontend filtrent pour n'afficher que les produits actifs.
- **Logs détaillés** : Ajout de logs à chaque étape importante, notamment lors de la sélection de magasin, de la création/ajustement de stock, et de la gestion des erreurs.
- **Retour d'objet créé** : Les endpoints POST (ex : création de produit) retournent l'objet complet créé, incluant son `_id` MongoDB, pour permettre un chaînage correct côté frontend.
- **Gestion stricte du magasin "Tous"** : Il est impossible d'ajuster le stock sur le magasin "Tous" (ce n'est pas un vrai magasin en base).
- **Gestion des erreurs** : Les erreurs courantes (ex : `Cast to ObjectId failed`, `duplicate key`) sont interceptées et renvoient des messages explicites avec le bon code HTTP.
- **Double validation JWT + session** : Toute route protégée vérifie à la fois le JWT et la session active en base (invalidation possible à tout moment).
- **Architecture MVC** : Séparation stricte entre modèles (Mongoose), contrôleurs (logique métier), routes (RESTful), et middlewares (auth, accès magasin, etc.).
- **Conventions de logs et d'API** : Respect du format `[MODULE][ACTION] Message` et des conventions REST (statuts, retours JSON, gestion d'erreurs).

---

## 📋 **Table des Matières**

- [Installation](#installation)
- [Configuration](#configuration)
- [Architecture Multi-Magasins](#architecture-multi-magasins)
- [API Endpoints](#api-endpoints)
- [Modèles de Données](#modèles-de-données)
- [Sécurité et Middlewares](#sécurité-et-middlewares)
- [Tests](#tests)
- [Logs et Debug](#logs-et-debug)
- [Exemples d'Utilisation](#exemples-dutilisation)

---

## 🚀 **Installation**

```bash
cd app/backend
npm install
```

## ⚙️ **Configuration**

### Variables d'environnement
Créer un fichier `.env` basé sur `.env.example` :

```env
# Base de données
MONGODB_URI=mongodb://localhost:27017/invoicestock

# JWT
JWT_SECRET=votre_secret_jwt_tres_securise
JWT_EXPIRES_IN=8h

# Serveur
PORT=3000
NODE_ENV=development
```

## 🏗️ **Architecture Multi-Magasins**

### **Principe**
- **Super-Admin** : Accès à tous les magasins
- **Gestionnaire** : Accès aux magasins assignés
- **Caissier** : Accès aux magasins assignés
- **Isolation** : Chaque utilisateur ne voit que ses données autorisées

### **Structure des Données**
```
User (assignedStores: [StoreId])
├── Store (isActive: boolean)
├── Product (createdBy: UserId)
├── Stock (productId + storeId unique)
├── StockMovement (productId + storeId)
└── StockAlert (productId + storeId)
```

---

## 🔌 **API Endpoints**

### **🔐 Authentification**
- `POST /api/auth/login` - Connexion avec JWT + session
- `POST /api/auth/logout` - Déconnexion (invalidation session)
- `GET /api/auth/verify` - Vérification session
- `GET /api/auth/session-info` - Informations session détaillées

### **👥 Gestion des Utilisateurs**
- `POST /api/users` - Création utilisateur (Super-Admin)
- `GET /api/users` - Liste utilisateurs (Super-Admin)
- `PUT /api/users/:id` - Modification utilisateur (Super-Admin)
- `PATCH /api/users/:id/activate` - Activation/désactivation (Super-Admin)
- `POST /api/users/:id/reveal-password` - Révéler mot de passe (Super-Admin)

### **🏪 Gestion des Magasins**
- `POST /api/stores` - Création magasin (Super-Admin)
- `GET /api/stores` - Liste magasins (selon accès)
- `PUT /api/stores/:id` - Modification magasin (Super-Admin)
- `DELETE /api/stores/:id` - Suppression magasin (Super-Admin)

### **📦 Gestion des Produits**
- `POST /api/products` - Création produit (selon accès)
- `GET /api/products` - Liste produits (filtrée par magasins)
- `GET /api/products/:id` - Détail produit (selon accès)
- `PUT /api/products/:id` - Modification produit (selon accès)
- `DELETE /api/products/:id` - Suppression produit (selon accès)
- `GET /api/products/categories` - Liste catégories (filtrée)

### **📊 Gestion des Stocks**
- `GET /api/stock` - Liste stocks (filtrée par magasins)
- `GET /api/stock/:storeId` - Stock par magasin (selon accès)
- `POST /api/stock/adjust` - Ajustement stock (selon accès)
- `POST /api/stock/reserve` - Réservation stock (selon accès)
- `POST /api/stock/release` - Libération réservation (selon accès)

### **📈 Mouvements de Stock**
- `GET /api/stock-movements` - Historique mouvements (filtré)
- `GET /api/stock-movements/:storeId` - Mouvements par magasin
- `POST /api/stock-movements` - Création mouvement (automatique)

### **⚠️ Alertes de Stock**
- `GET /api/stock-alerts` - Alertes actives (filtrées)
- `GET /api/stock-alerts/:storeId` - Alertes par magasin
- `PATCH /api/stock-alerts/:id/resolve` - Résoudre alerte

---

## 📊 **Modèles de Données**

### **👤 User**
```javascript
{
  username: String (unique, required),
  password: String (hashed, required),
  role: String (enum: ['super-admin', 'gestionnaire', 'caissier'], required),
  assignedStores: [ObjectId] (ref: Store),
  isActive: Boolean (default: true),
  tempPassword: String (généré automatiquement),
  hasTempPassword: Boolean (default: false),
  createdAt: Date,
  updatedAt: Date
}
```

### **🏪 Store**
```javascript
{
  name: String (required),
  address: String (required),
  city: String (required),
  phone: String (required),
  isActive: Boolean (default: true),
  createdAt: Date,
  updatedAt: Date
}
```

### **📦 Product**
```javascript
{
  name: String (required, indexed),
  description: String,
  category: String (indexed),
  unit: String (enum: ['pièce', 'kg', 'm', 'l'], required),
  purchasePrice: Number (required, min: 0),
  sellingPrice: Number (required, min: 0),
  barcode: String (unique, indexed),
  minStockLevel: Number (default: 0),
  maxStockLevel: Number (default: 1000),
  isActive: Boolean (default: true),
  createdBy: ObjectId (ref: User, required),
  createdAt: Date,
  updatedAt: Date,
  
  // Virtuals
  margin: Number (calculé: (sellingPrice - purchasePrice) / purchasePrice * 100),
  grossMargin: Number (calculé: sellingPrice - purchasePrice)
}
```

### **📊 Stock**
```javascript
{
  productId: ObjectId (ref: Product, required),
  storeId: ObjectId (ref: Store, required),
  quantity: Number (required, min: 0),
  reservedQuantity: Number (default: 0, min: 0),
  createdAt: Date,
  updatedAt: Date,
  
  // Virtuals
  availableQuantity: Number (calculé: Math.max(0, quantity - reservedQuantity)),
  isLowStock: Boolean (calculé: quantity <= 5),
  isOutOfStock: Boolean (calculé: quantity === 0)
}
```

### **📈 StockMovement**
```javascript
{
  productId: ObjectId (ref: Product, required),
  storeId: ObjectId (ref: Store, required),
  type: String (enum: ['add', 'remove', 'adjust', 'reserve', 'release'], required),
  quantity: Number (required),
  previousQuantity: Number (required),
  newQuantity: Number (required),
  reason: String (required),
  reference: String,
  performedBy: ObjectId (ref: User, required),
  createdAt: Date
}
```

### **⚠️ StockAlert**
```javascript
{
  productId: ObjectId (ref: Product, required),
  storeId: ObjectId (ref: Store, required),
  type: String (enum: ['low_stock', 'out_of_stock', 'overstock'], required),
  message: String (required),
  isActive: Boolean (default: true),
  resolvedAt: Date,
  resolvedBy: ObjectId (ref: User),
  createdAt: Date
}
```

### **🔐 Session**
```javascript
{
  userId: ObjectId (ref: User, required),
  token: String (unique, required),
  deviceInfo: {
    userAgent: String,
    ip: String,
    platform: String
  },
  isActive: Boolean (default: true),
  lastActivity: Date,
  expiresAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🛡️ **Sécurité et Middlewares**

### **🔐 Middleware d'Authentification**
```javascript
// verifyToken - Vérifie JWT + session active
// requireRole - Contrôle d'accès par rôle
// requireSuperAdmin - Accès Super-Admin uniquement
```

### **🏪 Middleware d'Accès Magasin**
```javascript
// checkStoreAccess - Vérifie accès à un magasin spécifique
// addStoreContext - Ajoute contexte magasin à la requête
// checkMultipleStoreAccess - Vérifie accès à plusieurs magasins
// checkHasAssignedStores - Vérifie que l'utilisateur a des magasins assignés
```

### **📊 Logique d'Accès**
- **Super-Admin** : Accès à tous les magasins et données
- **Gestionnaire** : Accès aux magasins dans `assignedStores`
- **Caissier** : Accès aux magasins dans `assignedStores`
- **Filtrage automatique** : Les requêtes sont filtrées selon les accès

---

## 🧪 **Tests**

### **Installation des Tests**
```bash
npm install jest supertest mongodb-memory-server --save-dev
```

### **Exécution des Tests**
```bash
# Tests complets
npm test

# Tests en mode watch
npm run test:watch

# Tests avec couverture
npm run test:coverage

# Tests simples (sans Jest)
node test-simple.js
node test-simple-integration.js
```

### **Structure des Tests**
```
tests/
├── setup.js                    # Configuration MongoDB en mémoire
├── utils/
│   └── testHelpers.js         # Utilitaires de test
├── models/
│   ├── Product.test.js        # Tests modèle Product
│   └── Stock.test.js          # Tests modèle Stock
├── controllers/
│   └── productController.test.js  # Tests contrôleur
└── middleware/
    └── storeAccessMiddleware.test.js  # Tests middleware
```

### **Couverture des Tests**
- ✅ **Modèles** : Validation, méthodes, virtuals
- ✅ **Contrôleurs** : CRUD, logique métier
- ✅ **Middlewares** : Sécurité, accès
- ✅ **Intégration** : End-to-end

---

## 📝 **Logs et Debug**

### **Format des Logs**
```
[MODULE][ACTION] Message descriptif
```

### **Exemples de Logs**
```
[AUTH][LOGIN] Tentative de connexion pour admin
[AUTH][MIDDLEWARE] Token et session valides pour admin (super-admin)
[USER][PUT] Modification utilisateur 1234567890abcdef
[PRODUCT][POST] Création produit "Ordinateur Portable" par admin
[STOCK][ADJUST] Ajustement stock +25 pour produit 1234567890abcdef
[STORE][ACCESS] Accès refusé au magasin 9876543210fedcba pour gestionnaire
```

### **Niveaux de Log**
- **INFO** : Opérations normales
- **WARN** : Situations inhabituelles
- **ERROR** : Erreurs à traiter
- **DEBUG** : Informations de débogage

---

## 💡 **Exemples d'Utilisation**

### **🔐 Connexion**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin", 
    "password": "admin123"
  }'
```

### **📦 Création Produit**
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ordinateur Portable",
    "description": "Ordinateur portable gaming",
    "category": "Informatique",
    "unit": "pièce",
    "purchasePrice": 800.0,
    "sellingPrice": 1200.0,
    "minStockLevel": 5,
    "maxStockLevel": 50
  }'
```

### **📊 Ajustement Stock**
```bash
curl -X POST http://localhost:3000/api/stock/adjust \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "1234567890abcdef",
    "storeId": "9876543210fedcba",
    "quantity": 25,
    "type": "add",
    "reason": "Réception commande",
    "reference": "CMD-001"
  }'
```

### **🏪 Récupération Stock par Magasin**
```bash
curl -X GET http://localhost:3000/api/stock/9876543210fedcba \
  -H "Authorization: Bearer <token>"
```

---

## 🚀 **Lancement en Développement**

```bash
# Installation
npm install

# Variables d'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# Lancement
npm run dev

# Tests
npm test
```

---

## 📋 **Fonctionnalités Avancées**

### **🔄 Synchronisation Multi-Magasins**
- Stock isolé par magasin
- Mouvements tracés par magasin
- Alertes spécifiques par magasin
- Calculs de marge automatiques

### **📊 Gestion des Stocks**
- Ajout/retrait de stock
- Réservation de stock
- Détection automatique des alertes
- Historique complet des mouvements

### **⚠️ Système d'Alertes**
- Stock faible (≤ 5 unités)
- Rupture de stock (0 unité)
- Surstock (≥ maxStockLevel)
- Résolution manuelle des alertes

### **🔐 Sécurité Renforcée**
- Sessions en base de données
- Validation double JWT + session
- Contrôle d'accès granulaire
   - Logs détaillés de toutes les opérations

---

## 🎯 **Prochaines Étapes**

- [ ] Tests d'intégration end-to-end
- [ ] API de rapports et statistiques
- [ ] Notifications en temps réel
- [ ] Export/import de données
- [ ] Sauvegarde automatique

---

**Le backend multi-magasins est prêt pour l'intégration frontend !** 🚀 