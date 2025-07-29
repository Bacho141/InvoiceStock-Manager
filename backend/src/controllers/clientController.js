import Client from '../models/Client.js';

export const createClient = async (req, res) => {
  try {
    const { firstName, lastName, phone, email, address } = req.body;
    if (!firstName || !lastName || !phone) {
      return res.status(400).json({ message: 'firstName, lastName et phone sont requis.' });
    }
    const client = await Client.create({ firstName, lastName, phone, email, address });
    res.status(201).json({ message: 'Client créé', data: client });
  } catch (error) {
    res.status(500).json({ message: 'Erreur création client', error: error.message });
  }
};

export const getClients = async (req, res) => {
  try {
    const clients = await Client.find().sort({ createdAt: -1 });
    res.json({ data: clients });
  } catch (error) {
    res.status(500).json({ message: 'Erreur récupération clients', error: error.message });
  }
};

export const getClientById = async (req, res) => {
  try {
    const client = await Client.findById(req.params.id);
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    res.json({ data: client });
  } catch (error) {
    res.status(500).json({ message: 'Erreur récupération client', error: error.message });
  }
};

export const updateClient = async (req, res) => {
  try {
    const client = await Client.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    res.json({ message: 'Client mis à jour', data: client });
  } catch (error) {
    res.status(500).json({ message: 'Erreur mise à jour client', error: error.message });
  }
};

export const deleteClient = async (req, res) => {
  try {
    const client = await Client.findByIdAndDelete(req.params.id);
    if (!client) return res.status(404).json({ message: 'Client non trouvé' });
    res.json({ message: 'Client supprimé' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur suppression client', error: error.message });
  }
}; 