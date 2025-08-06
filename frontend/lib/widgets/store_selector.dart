import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/store.dart';
import '../services/store_service.dart';

class StoreSelector extends StatefulWidget {
  final Function(Store) onStoreChanged;
  final Store? currentStore;

  const StoreSelector({
    Key? key,
    required this.onStoreChanged,
    this.currentStore,
  }) : super(key: key);

  @override
  State<StoreSelector> createState() => _StoreSelectorState();
}

class _StoreSelectorState extends State<StoreSelector> {
  List<Store> stores = [];
  Store? selectedStore;
  bool isLoading = true;
  final StoreService _storeService = StoreService();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  // Méthode publique pour rafraîchir les magasins
  Future<void> refreshStores() async {
    setState(() {
      isLoading = true;
    });
    await _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      debugPrint('[WIDGET][StoreSelector] Chargement des magasins via API...');

      // Utiliser le service API pour récupérer les magasins en temps réel
      final apiStores = await _storeService.getStores();

      // Ajout de l'option 'Tous' en tête de liste
      final allStore = Store(
        id: 'all',
        name: 'Tous',
        address: '',
        isActive: true,
        logoUrl: null,
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setState(() {
        stores = [allStore, ...apiStores];
        selectedStore =
            widget.currentStore ?? (stores.isNotEmpty ? stores.first : null);
        isLoading = false;
      });

      debugPrint(
        '[WIDGET][StoreSelector] ${stores.length} magasins chargés via API',
      );

      // Mettre à jour SharedPreferences avec les nouvelles données
      if (stores.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final storesJson = jsonEncode(stores.map((s) => s.toJson()).toList());
        await prefs.setString('assigned_stores', storesJson);
        debugPrint('[WIDGET][StoreSelector] SharedPreferences mis à jour');
      }
    } catch (e) {
      debugPrint('[WIDGET][StoreSelector] Erreur chargement API: $e');

      // Fallback vers SharedPreferences en cas d'erreur API
      try {
        final prefs = await SharedPreferences.getInstance();
        final storesJson = prefs.getString('assigned_stores');

        if (storesJson != null) {
          final storesList = jsonDecode(storesJson) as List;
          setState(() {
            stores = storesList.map((s) => Store.fromJson(s)).toList();
            selectedStore =
                widget.currentStore ??
                (stores.isNotEmpty ? stores.first : null);
            isLoading = false;
          });
          debugPrint(
            '[WIDGET][StoreSelector] Fallback: ${stores.length} magasins chargés depuis SharedPreferences',
          );
        } else {
          setState(() {
            isLoading = false;
          });
          debugPrint('[WIDGET][StoreSelector] Aucun magasin trouvé (fallback)');
        }
      } catch (fallbackError) {
        debugPrint('[WIDGET][StoreSelector] Erreur fallback: $fallbackError');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher si un seul magasin ou aucun magasin
    if (stores.length <= 1) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Chargement des magasins...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF7717E8), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Magasin:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF7717E8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Store>(
                value: selectedStore,
                hint: const Text('Sélectionner un magasin'),
                isExpanded: true,
                items: stores.map((store) {
                  return DropdownMenuItem<Store>(
                    value: store,
                    child: Row(
                      children: [
                        Icon(
                          store.isActive ? Icons.check_circle : Icons.cancel,
                          color: store.isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: store.isActive
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Store? newStore) async {
                  if (newStore != null) {
                    setState(() {
                      selectedStore = newStore;
                    });
                    widget.onStoreChanged(newStore);
                    debugPrint(
                      '[WIDGET][StoreSelector] Magasin sélectionné: ${newStore.name}',
                    );
                    // Stocke l’ID du magasin sélectionné
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selected_store_id', newStore.id);
                    debugPrint('[STORE_SELECTOR] SAUVEGARDE DANS PREFS: selected_store_id = ${newStore.id}');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
