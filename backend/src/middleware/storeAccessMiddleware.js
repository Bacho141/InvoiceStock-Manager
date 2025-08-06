import User from '../models/User.js';

/**
 * Middleware pour vérifier l'accès à un magasin spécifique
 * Utilisé pour les routes qui nécessitent un storeId dans les paramètres
 */
export const checkStoreAccess = async (req, res, next) => {
  console.log('[STORE_ACCESS_MIDDLEWARE] Exécution pour la route:', req.originalUrl);
  
  try {
    const { storeId } = req.params;
    const user = req.user;
    
    console.log('[STORE_ACCESS_MIDDLEWARE] storeId reçu (params): ', storeId);
    console.log('[STORE_ACCESS_MIDDLEWARE] Utilisateur:', user ? user.username : 'Non authentifié');

    if (!user) {
      return res.status(401).json({ message: 'Utilisateur non authentifié.' });
    }

    if (!storeId) {
      console.log('[STORE_ACCESS_MIDDLEWARE] ERREUR: Aucun storeId fourni dans les paramètres de la route.');
      return res.status(400).json({ 
        message: 'ID du magasin manquant dans l\'URL' 
      });
    }
    
    if (user.role === 'super-admin') {
      console.log('[STORE_ACCESS_MIDDLEWARE] Accès autorisé pour Super-admin.');
      return next();
    }
    
    const hasAccess = user.assignedStores.some(
      store => store.toString() === storeId
    );
    
    if (!hasAccess) {
      console.log(`[STORE_ACCESS_MIDDLEWARE] REFUS: L\'utilisateur ${user.username} n\'a pas accès au magasin ${storeId}.`);
      return res.status(403).json({
        message: 'Accès refusé à ce magasin'
      });
    }
    
    console.log(`[STORE_ACCESS_MIDDLEWARE] AUTORISÉ: L\'utilisateur ${user.username} a accès au magasin ${storeId}.`);
    next();
  } catch (error) {
    console.error('[STORE][ACCESS] Erreur:', error.message);
    res.status(500).json({ 
      message: 'Erreur lors de la vérification d\'accès',
      error: 'STORE_ACCESS_ERROR'
    });
  }
};

/**
 * Middleware pour ajouter le contexte magasin aux requêtes
 * Utilisé pour filtrer les données selon les magasins assignés
 */
export const addStoreContext = async (req, res, next) => {
  console.log('[STORE][CONTEXT] Ajout contexte magasin');
  
  try {
    const user = req.user;
    
    // Super-admin peut voir tous les magasins
    if (user.role === 'super-admin') {
      req.storeContext = { 
        allStores: true,
        userRole: 'super-admin'
      };
      console.log('[STORE][CONTEXT] Super-admin - accès à tous les magasins');
    } else {
      // Autres rôles : seulement leurs magasins assignés
      req.storeContext = { 
        assignedStores: user.assignedStores,
        userRole: user.role
      };
      console.log('[STORE][CONTEXT] Utilisateur - magasins assignés:', user.assignedStores.length);
    }
    
    next();
  } catch (error) {
    console.error('[STORE][CONTEXT] Erreur:', error.message);
    res.status(500).json({ 
      message: 'Erreur lors de l\'ajout du contexte magasin',
      error: 'STORE_CONTEXT_ERROR'
    });
  }
};

/**
 * Middleware pour vérifier l'accès à plusieurs magasins
 * Utilisé pour les opérations en lot
 */
export const checkMultipleStoreAccess = async (req, res, next) => {
  console.log('[STORE][MULTI] Vérification accès multiple magasins');
  
  try {
    const { storeIds } = req.body;
    const user = req.user;
    
    if (!storeIds || !Array.isArray(storeIds)) {
      console.log('[STORE][MULTI] Aucun storeIds fourni ou format invalide');
      return res.status(400).json({ 
        message: 'Liste des IDs de magasins requise' 
      });
    }
    
    // Super-admin a accès à tous les magasins
    if (user.role === 'super-admin') {
      console.log('[STORE][MULTI] Super-admin - accès autorisé');
      return next();
    }
    
    // Vérifier si l'utilisateur a accès à tous les magasins demandés
    const userStoreIds = user.assignedStores.map(store => store.toString());
    const hasAccessToAll = storeIds.every(storeId => 
      userStoreIds.includes(storeId)
    );
    
    if (!hasAccessToAll) {
      console.log('[STORE][MULTI] Accès refusé pour utilisateur:', user.username);
      return res.status(403).json({ 
        message: 'Accès refusé à un ou plusieurs magasins',
        error: 'MULTI_STORE_ACCESS_DENIED'
      });
    }
    
    console.log('[STORE][MULTI] Accès autorisé pour utilisateur:', user.username);
    next();
  } catch (error) {
    console.error('[STORE][MULTI] Erreur:', error.message);
    res.status(500).json({ 
      message: 'Erreur lors de la vérification d\'accès multiple',
      error: 'MULTI_STORE_ACCESS_ERROR'
    });
  }
};

/**
 * Middleware pour vérifier si l'utilisateur a au moins un magasin assigné
 */
export const checkHasAssignedStores = async (req, res, next) => {
  console.log('[STORE][ASSIGNED] Vérification magasins assignés');
  
  try {
    const user = req.user;
    
    // Super-admin a toujours accès
    if (user.role === 'super-admin') {
      console.log('[STORE][ASSIGNED] Super-admin - toujours autorisé');
      return next();
    }
    
    // Vérifier si l'utilisateur a des magasins assignés
    if (!user.assignedStores || user.assignedStores.length === 0) {
      console.log('[STORE][ASSIGNED] Aucun magasin assigné pour:', user.username);
      return res.status(403).json({ 
        message: 'Aucun magasin assigné à votre compte',
        error: 'NO_ASSIGNED_STORES'
      });
    }
    
    console.log('[STORE][ASSIGNED] Magasins assignés OK pour:', user.username);
    next();
  } catch (error) {
    console.error('[STORE][ASSIGNED] Erreur:', error.message);
    res.status(500).json({ 
      message: 'Erreur lors de la vérification des magasins assignés',
      error: 'ASSIGNED_STORES_ERROR'
    });
  }
}; 