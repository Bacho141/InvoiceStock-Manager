import Client from '../models/Client.js';
import creanceService from '../services/creanceService.js';

export const createClient = async (req, res) => {
  try {
    const { firstName, lastName, phone, email, address, company, customerType, city, region, assignedStore, creditLimit, paymentTerms, category, priority, assignedSalesperson, preferredPaymentMethod, notes } = req.body;
    
    if (!firstName || !lastName || !phone) {
      return res.status(400).json({ message: 'firstName, lastName et phone sont requis.' });
    }
    
    const clientData = {
      firstName,
      lastName,
      phone,
      email,
      address,
      company,
      customerType: customerType || 'particulier',
      city,
      region,
      assignedStore,
      creditLimit: creditLimit || 0,
      paymentTerms: paymentTerms || 30,
      category: category || 'particulier',
      priority: priority || 'normal',
      assignedSalesperson,
      preferredPaymentMethod: preferredPaymentMethod || 'especes',
      notes
    };
    
    const client = await Client.create(clientData);
    console.log(`[CLIENT][CREATE] Nouveau client créé: ${client.fullName}`);
    res.status(201).json({ message: 'Client créé', data: client });
  } catch (error) {
    console.error('[CLIENT][CREATE] Erreur création client:', error);
    res.status(500).json({ message: 'Erreur création client', error: error.message });
  }
};

export const getClients = async (req, res) => {
  try {
    const { search, status, category, assignedStore, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
    
    let query = {};
    
    // Filtres
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { company: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (status) query.status = status;
    if (category) query.category = category;
    if (assignedStore) query.assignedStore = assignedStore;
    
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'asc' ? 1 : -1;
    
    const clients = await Client.find(query)
      .populate('assignedStore', 'name')
      .populate('assignedSalesperson', 'username')
      .sort(sortOptions);
      
    res.json({ data: clients });
  } catch (error) {
    console.error('[CLIENT][GET] Erreur récupération clients:', error);
    res.status(500).json({ message: 'Erreur récupération clients', error: error.message });
  }
};

export const getClientById = async (req, res) => {
  try {
    const client = await Client.findById(req.params.id)
      .populate('assignedStore', 'name')
      .populate('assignedSalesperson', 'username')
      .populate('purchaseHistory');
      
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    
    // Calcul des créances en temps réel
    const outstandingData = await creanceService.calculateClientOutstanding(client._id);
    
    const clientWithMetrics = {
      ...client.toObject(),
      currentOutstanding: outstandingData.totalOutstanding,
      overdueAmount: outstandingData.overdueAmount,
      invoicesByAge: outstandingData.invoicesByAge
    };
    
    res.json({ data: clientWithMetrics });
  } catch (error) {
    console.error('[CLIENT][GET_BY_ID] Erreur récupération client:', error);
    res.status(500).json({ message: 'Erreur récupération client', error: error.message });
  }
};

export const updateClient = async (req, res) => {
  try {
    const client = await Client.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    
    // Recalculer le score après mise à jour
    try {
      await creanceService.updateClientScore(client._id);
    } catch (scoreError) {
      console.warn('[CLIENT][UPDATE] Erreur recalcul score:', scoreError);
    }
    
    console.log(`[CLIENT][UPDATE] Client mis à jour: ${client.fullName}`);
    res.json({ message: 'Client mis à jour', data: client });
  } catch (error) {
    console.error('[CLIENT][UPDATE] Erreur mise à jour client:', error);
    res.status(500).json({ message: 'Erreur mise à jour client', error: error.message });
  }
};

export const deleteClient = async (req, res) => {
  try {
    const client = await Client.findByIdAndDelete(req.params.id);
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    
    console.log(`[CLIENT][DELETE] Client supprimé: ${client.fullName}`);
    res.json({ message: 'Client supprimé' });
  } catch (error) {
    console.error('[CLIENT][DELETE] Erreur suppression client:', error);
    res.status(500).json({ message: 'Erreur suppression client', error: error.message });
  }
};

// Nouvelles fonctionnalités selon le plan Sprint 1

export const addCommunication = async (req, res) => {
  try {
    const { id } = req.params;
    const { type, subject, content } = req.body;
    const userId = req.user._id;
    
    if (!type || !content) {
      return res.status(400).json({ message: 'Type et contenu requis' });
    }
    
    const client = await Client.findById(id);
    if (!client) {
      return res.status(404).json({ message: 'Client non trouvé' });
    }
    
    const communication = {
      type,
      subject,
      content,
      userId,
      date: new Date()
    };
    
    client.communicationHistory.push(communication);
    await client.save();
    
    console.log(`[CLIENT][COMMUNICATION] Ajoutée pour ${client.fullName}:`, type);
    res.json({ message: 'Communication ajoutée', data: communication });
  } catch (error) {
    console.error('[CLIENT][COMMUNICATION] Erreur ajout communication:', error);
    res.status(500).json({ message: 'Erreur ajout communication', error: error.message });
  }
};

export const updateScore = async (req, res) => {
  try {
    const { id } = req.params;
    
    const newScore = await creanceService.updateClientScore(id);
    
    res.json({ 
      message: 'Score mis à jour', 
      data: { 
        clientId: id, 
        newScore 
      } 
    });
  } catch (error) {
    console.error('[CLIENT][SCORE] Erreur mise à jour score:', error);
    res.status(500).json({ message: 'Erreur mise à jour score', error: error.message });
  }
};

export const refreshMetrics = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Recalcul des métriques
    const outstandingData = await creanceService.calculateClientOutstanding(id);
    const client = await Client.findById(id);
    
    if (!client) {
      return res.status(404).json({ message: 'Client non trouvé' });
    }
    
    // Mise à jour du client
    await Client.findByIdAndUpdate(id, {
      currentOutstanding: outstandingData.totalOutstanding
    });
    
    // Recalcul du score
    const newScore = await creanceService.updateClientScore(id);
    
    console.log(`[CLIENT][METRICS] Métriques actualisées pour ${client.fullName}`);
    res.json({ 
      message: 'Métriques actualisées', 
      data: {
        outstandingData,
        newScore
      }
    });
  } catch (error) {
    console.error('[CLIENT][METRICS] Erreur actualisation métriques:', error);
    res.status(500).json({ message: 'Erreur actualisation métriques', error: error.message });
  }
}; 