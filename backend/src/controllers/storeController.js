import Store from '../models/Store.js';

export const createStore = async (req, res) => {
  console.log('[STORE][CREATE] Création magasin par', req.user.username);
  console.log('[STORE][CREATE] User ID:', req.user.userId);
  console.log('[STORE][CREATE] User object:', JSON.stringify(req.user, null, 2));
  
  try {
    // Seul le super-admin peut créer des magasins
    if (req.user.role !== 'super-admin') {
      console.log('[STORE][CREATE] Accès refusé - rôle:', req.user.role);
      return res.status(403).json({ 
        message: 'Seul le super-admin peut créer des magasins.' 
      });
    }

    // Vérifier que l'ID utilisateur est présent
    if (!req.user.userId) {
      console.error('[STORE][CREATE] ID utilisateur manquant');
      return res.status(500).json({ message: 'ID utilisateur manquant.' });
    }

    const storeData = {
      ...req.body,
      createdBy: req.user.userId
    };
    
    console.log('[STORE][CREATE] Données du magasin:', JSON.stringify(storeData, null, 2));

    const store = await Store.create(storeData);

    console.log('[STORE][CREATE] Magasin créé:', store.name);
    res.status(201).json({ success: true, data: store });
  } catch (error) {
    console.error('[STORE][CREATE] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

export const getStores = async (req, res) => {
  console.log('[STORE][GET] Liste magasins demandée par', req.user.username);
  
  try {
    let stores;
    
    if (req.user.role === 'super-admin') {
      // Super-admin voit tous les magasins
      stores = await Store.find({ isActive: true }).populate('createdBy', 'username');
      console.log('[STORE][GET] Super-admin - tous les magasins retournés');
    } else {
      // Autres utilisateurs voient seulement leurs magasins assignés
      stores = await Store.find({
        _id: { $in: req.user.assignedStores },
        isActive: true
      }).populate('createdBy', 'username');
      console.log('[STORE][GET] Utilisateur - magasins assignés retournés');
    }

    console.log('[STORE][GET]', stores.length, 'magasins retournés');
    res.json({ success: true, data: stores });
  } catch (error) {
    console.error('[STORE][GET] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

export const getStoreById = async (req, res) => {
  console.log('[STORE][GET_BY_ID] Magasin demandé par', req.user.username);
  
  try {
    const { id } = req.params;
    const store = await Store.findById(id).populate('createdBy', 'username');

    if (!store) {
      console.log('[STORE][GET_BY_ID] Magasin non trouvé:', id);
      return res.status(404).json({ message: 'Magasin non trouvé.' });
    }

    // Vérifier l'accès
    if (req.user.role !== 'super-admin' && !req.user.assignedStores.includes(id)) {
      console.log('[STORE][GET_BY_ID] Accès refusé au magasin:', id);
      return res.status(403).json({ message: 'Accès non autorisé à ce magasin.' });
    }

    console.log('[STORE][GET_BY_ID] Magasin retourné:', store.name);
    res.json({ success: true, data: store });
  } catch (error) {
    console.error('[STORE][GET_BY_ID] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

export const updateStore = async (req, res) => {
  console.log('[STORE][UPDATE] Mise à jour magasin par', req.user.username);
  
  try {
    const { id } = req.params;

    // Seul le super-admin peut modifier des magasins
    if (req.user.role !== 'super-admin') {
      console.log('[STORE][UPDATE] Accès refusé - rôle:', req.user.role);
      return res.status(403).json({ 
        message: 'Seul le super-admin peut modifier des magasins.' 
      });
    }

    const store = await Store.findByIdAndUpdate(
      id,
      { ...req.body },
      { new: true, runValidators: true }
    ).populate('createdBy', 'username');

    if (!store) {
      console.log('[STORE][UPDATE] Magasin non trouvé:', id);
      return res.status(404).json({ message: 'Magasin non trouvé.' });
    }

    console.log('[STORE][UPDATE] Magasin mis à jour:', store.name);
    res.json({ success: true, data: store });
  } catch (error) {
    console.error('[STORE][UPDATE] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

export const toggleStoreStatus = async (req, res) => {
  console.log('[STORE][TOGGLE] Changement statut magasin par', req.user.username);
  
  try {
    const { id } = req.params;

    // Seul le super-admin peut changer le statut des magasins
    if (req.user.role !== 'super-admin') {
      console.log('[STORE][TOGGLE] Accès refusé - rôle:', req.user.role);
      return res.status(403).json({ 
        message: 'Seul le super-admin peut changer le statut des magasins.' 
      });
    }

    const store = await Store.findById(id);
    if (!store) {
      console.log('[STORE][TOGGLE] Magasin non trouvé:', id);
      return res.status(404).json({ message: 'Magasin non trouvé.' });
    }

    store.isActive = !store.isActive;
    await store.save();

    console.log('[STORE][TOGGLE] Statut changé:', store.name, '- Actif:', store.isActive);
    res.json({ success: true, data: store });
  } catch (error) {
    console.error('[STORE][TOGGLE] Erreur:', error.message);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
}; 