import Product from '../models/Product.js';
import Stock from '../models/Stock.js';

/**
 * Récupérer tous les produits avec contexte multi-magasins
 */
const getAllProducts = async (req, res) => {
  console.log('[PRODUCT][GET_ALL] Récupération des produits');
  
  try {
    const { storeContext } = req;
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      category = '', 
      isActive // pas de valeur par défaut !
    } = req.query;
    
    // Construire le filtre de base
    let filter = {};
    if (typeof isActive !== 'undefined') {
      filter.isActive = isActive === 'true' || isActive === true;
    }
    
    // Ajouter la recherche par nom ou description
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Ajouter le filtre par catégorie
    if (category) {
      filter.category = category;
    }
    
    // Calculer la pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Récupérer les produits
    const products = await Product.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('createdBy', 'username');
    
    // Compter le total
    const total = await Product.countDocuments(filter);
    
    // On retourne toujours la liste complète des produits trouvés par le filtre
    console.log('[PRODUCT][GET_ALL] Produits récupérés:', products.length);
    res.json({
      success: true,
      data: products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('[PRODUCT][GET_ALL] Erreur:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la récupération des produits',
      error: error.message 
    });
  }
};

/**
 * Récupérer un produit par ID
 */
const getProduct = async (req, res) => {
  console.log('[PRODUCT][GET] Récupération produit:', req.params.id);
  
  try {
    const { id } = req.params;
    const { storeContext } = req;
    
    const product = await Product.findById(id)
      .populate('createdBy', 'username');
    
    if (!product) {
      console.log('[PRODUCT][GET] Produit non trouvé');
      return res.status(404).json({ 
        success: false,
        message: 'Produit non trouvé' 
      });
    }
    
    // Si l'utilisateur n'est pas super-admin, vérifier qu'il a accès au produit
    if (!storeContext.allStores) {
      const stock = await Stock.findOne({
        productId: id,
        storeId: { $in: storeContext.assignedStores }
      });
      
      if (!stock) {
        console.log('[PRODUCT][GET] Accès refusé - produit non accessible');
        return res.status(403).json({ 
          success: false,
          message: 'Accès refusé à ce produit' 
        });
      }
    }
    
    console.log('[PRODUCT][GET] Produit récupéré avec succès');
    
    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    console.error('[PRODUCT][GET] Erreur:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la récupération du produit',
      error: error.message 
    });
  }
};

/**
 * Créer un nouveau produit
 */
const createProduct = async (req, res) => {
  console.log('[PRODUCT][CREATE] Création nouveau produit');
  
  try {
    const {
      name,
      reference,
      description,
      category,
      unit,
      purchasePrice,
      sellingPrice,
      minStockLevel,
      maxStockLevel
    } = req.body;

    // On ne prend jamais createdBy du body !
    const userId = req.user._id;

    // Validation des données
    if (!name || !reference || !purchasePrice || !sellingPrice) {
      console.log('[PRODUCT][CREATE] Données manquantes');
      return res.status(400).json({
        success: false,
        message: 'Nom, référence, prix d\'achat et prix de vente sont requis'
      });
    }

    // Vérifier si la référence existe déjà
    const existingRef = await Product.findOne({ reference });
    if (existingRef) {
      console.log('[PRODUCT][CREATE] Référence déjà existante');
      return res.status(400).json({
        success: false,
        message: 'Cette référence existe déjà'
      });
    }

    // Créer le produit (createdBy injecté côté serveur)
    const product = new Product({
      name,
      reference,
      description,
      category,
      unit,
      purchasePrice,
      sellingPrice,
      minStockLevel: minStockLevel || 0,
      maxStockLevel: maxStockLevel || 0,
      createdBy: userId
    });

    await product.save();

    console.log('[PRODUCT][CREATE] Produit créé avec succès:', product._id);

    // Récupérer le produit avec les relations
    const createdProduct = await Product.findById(product._id)
      .populate('createdBy', 'username');

    res.status(201).json({
      success: true,
      message: 'Produit créé avec succès',
      data: createdProduct
    });
  } catch (error) {
    console.error('[PRODUCT][CREATE] Erreur:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du produit',
      error: error.message
    });
  }
};

/**
 * Mettre à jour un produit
 */
const updateProduct = async (req, res) => {
  console.log('[PRODUCT][UPDATE] Mise à jour produit:', req.params.id);
  
  try {
    const { id } = req.params;
    const {
      name,
      reference,
      description,
      category,
      unit,
      purchasePrice,
      sellingPrice,
      minStockLevel,
      maxStockLevel,
      isActive
    } = req.body;
    
    const { storeContext } = req;
    
    // Vérifier l'accès au produit
    if (!storeContext.allStores) {
      const stock = await Stock.findOne({
        productId: id,
        storeId: { $in: storeContext.assignedStores }
      });
      
      if (!stock) {
        console.log('[PRODUCT][UPDATE] Accès refusé - produit non accessible');
        return res.status(403).json({
          success: false,
          message: 'Accès refusé à ce produit'
        });
      }
    }
    
    // Vérifier si le produit existe
    const existingProduct = await Product.findById(id);
    if (!existingProduct) {
      console.log('[PRODUCT][UPDATE] Produit non trouvé');
      return res.status(404).json({
        success: false,
        message: 'Produit non trouvé'
      });
    }
    
    // Vérifier si la référence existe déjà (sauf pour ce produit)
    if (reference && reference !== existingProduct.reference) {
      const duplicateRef = await Product.findOne({ reference, _id: { $ne: id } });
      if (duplicateRef) {
        console.log('[PRODUCT][UPDATE] Référence déjà existante');
        return res.status(400).json({
          success: false,
          message: 'Cette référence existe déjà'
        });
      }
    }
    
    // Mettre à jour le produit
    const updatedProduct = await Product.findByIdAndUpdate(
      id,
      {
        name,
        reference,
        description,
        category,
        unit,
        purchasePrice,
        sellingPrice,
        minStockLevel,
        maxStockLevel,
        isActive,
        updatedAt: new Date()
      },
      { new: true, runValidators: true }
    ).populate('createdBy', 'username');
    
    console.log('[PRODUCT][UPDATE] Produit mis à jour avec succès');
    
    res.json({
      success: true,
      message: 'Produit mis à jour avec succès',
      data: updatedProduct
    });
  } catch (error) {
    console.error('[PRODUCT][UPDATE] Erreur:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du produit',
      error: error.message
    });
  }
};

/**
 * Supprimer un produit (désactivation logique)
 */
const deleteProduct = async (req, res) => {
  console.log('[PRODUCT][DELETE] Suppression produit:', req.params.id);
  
  try {
    const { id } = req.params;
    const { storeContext } = req;
    
    // Vérifier l'accès au produit
    if (!storeContext.allStores) {
      const stock = await Stock.findOne({
        productId: id,
        storeId: { $in: storeContext.assignedStores }
      });
      
      if (!stock) {
        console.log('[PRODUCT][DELETE] Accès refusé - produit non accessible');
        return res.status(403).json({ 
          success: false,
          message: 'Accès refusé à ce produit' 
        });
      }
    }
    
    // Vérifier si le produit existe
    const product = await Product.findById(id);
    if (!product) {
      console.log('[PRODUCT][DELETE] Produit non trouvé');
      return res.status(404).json({ 
        success: false,
        message: 'Produit non trouvé' 
      });
    }
    
    // Désactiver le produit (suppression logique)
    product.isActive = false;
    product.updatedAt = new Date();
    await product.save();
    
    console.log('[PRODUCT][DELETE] Produit désactivé avec succès');
    
    res.json({
      success: true,
      message: 'Produit supprimé avec succès'
    });
  } catch (error) {
    console.error('[PRODUCT][DELETE] Erreur:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la suppression du produit',
      error: error.message 
    });
  }
};

/**
 * Récupérer les catégories de produits
 */
const getCategories = async (req, res) => {
  console.log('[PRODUCT][CATEGORIES] Récupération des catégories');
  
  try {
    const { storeContext } = req;
    
    let filter = { isActive: true };
    
    // Si l'utilisateur n'est pas super-admin, filtrer par magasins assignés
    if (!storeContext.allStores) {
      const stocks = await Stock.find({ 
        storeId: { $in: storeContext.assignedStores } 
      }).distinct('productId');
      
      filter._id = { $in: stocks };
    }
    
    const categories = await Product.distinct('category', filter);
    const filteredCategories = categories.filter(cat => cat && cat.trim() !== '');
    
    console.log('[PRODUCT][CATEGORIES] Catégories récupérées:', filteredCategories.length);
    
    res.json({
      success: true,
      data: filteredCategories
    });
  } catch (error) {
    console.error('[PRODUCT][CATEGORIES] Erreur:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Erreur lors de la récupération des catégories',
      error: error.message 
    });
  }
};



/**
 * Récupérer tous les produits avec leur stock agrégé pour les magasins accessibles.
 */
const getAllProductsWithAggregatedStock = async (req, res) => {
  console.log('[PRODUCT][GET_ALL_AGGREGATED_STOCK] Récupération des produits avec stock agrégé');

  try {
    const { storeContext } = req; // Contient assignedStores et allStores

    // Si l'utilisateur n'a pas accès à tous les magasins et n'a pas de magasins assignés,
    // ou si aucun magasin n'est assigné, retourner une liste vide.
    if (!storeContext.allStores && (!storeContext.assignedStores || storeContext.assignedStores.length === 0)) {
      console.log('[PRODUCT][GET_ALL_AGGREGATED_STOCK] Aucun magasin assigné, retour d\'une liste vide.');
      return res.json({ success: true, data: [], pagination: { total: 0 } });
    }

    // Pipeline d'agrégation
    const pipeline = [];

    // 1. Matcher les produits actifs
    pipeline.push({
      $match: { isActive: true }
    });

    // 2. Joindre avec la collection Stock pour obtenir les quantités
    pipeline.push({
      $lookup: {
        from: 'stocks', // Nom de la collection Stock (généralement en minuscules et pluriel)
        localField: '_id',
        foreignField: 'productId',
        as: 'stockInfo'
      }
    });

    // 3. Filtrer les stocks par les magasins accessibles à l'utilisateur
    // Si l'utilisateur n'est pas super-admin, filtrer par assignedStores
    if (!storeContext.allStores) {
      pipeline.push({
        $addFields: {
          stockInfo: {
            $filter: {
              input: '$stockInfo',
              as: 'stock',
              cond: { $in: ['$stock.storeId', storeContext.assignedStores] }
            }
          }
        }
      });
    }

    // 4. Calculer la quantité totale de stock disponible pour chaque produit
    pipeline.push({
      $addFields: {
        totalStockQuantity: { $sum: '$stockInfo.quantity' }
      }
    });

    // 5. Projeter les champs nécessaires et ajouter les champs de stock enrichis
    pipeline.push({
      $project: {
        _id: 1,
        name: 1,
        reference: 1,
        description: 1,
        category: 1,
        unit: 1,
        purchasePrice: 1,
        sellingPrice: 1,
        minStockLevel: 1,
        maxStockLevel: 1,
        isActive: 1,
        createdAt: 1,
        updatedAt: 1,
        createdBy: 1, // Conserver createdBy si nécessaire pour populate
        stockQuantity: '$totalStockQuantity', // Quantité totale agrégée
        reservedQuantity: { $sum: '$stockInfo.reserved' }, // Agrège les quantités réservées
        availableQuantity: { $subtract: ['$totalStockQuantity', { $sum: '$stockInfo.reserved' }] }, // Stock disponible
        isAvailable: { $gt: [{ $subtract: ['$totalStockQuantity', { $sum: '$stockInfo.reserved' }] }, 0] }, // Est disponible si stock > 0
        isLowStock: { $and: [
          { $gt: ['$totalStockQuantity', 0] }, // Pas en rupture totale
          { $lte: ['$totalStockQuantity', '$minStockLevel'] } // Mais en dessous du seuil min
        ]}
      }
    });

    // 6. Exécuter l'agrégation
    const products = await Product.aggregate(pipeline);

    console.log('[PRODUCT][GET_ALL_AGGREGATED_STOCK] Produits agrégés récupérés:', products.length);
    console.log('[PRODUCT][GET_ALL_AGGREGATED_STOCK] Exemple produit:', JSON.stringify(products[0], null, 2));

    res.json({
      success: true,
      data: products,
      pagination: { // La pagination est plus complexe avec l'agrégation, ici c'est simplifié
        total: products.length,
        page: 1,
        limit: products.length // Retourne tout pour l'instant
      }
    });

  } catch (error) {
    console.error('[PRODUCT][GET_ALL_AGGREGATED_STOCK] Erreur:', error.message);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des produits avec stock agrégé',
      error: error.message
    });
  }
};

export default {
  getAllProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  getCategories,
  getAllProductsWithAggregatedStock // Exporter la nouvelle fonction
}; 