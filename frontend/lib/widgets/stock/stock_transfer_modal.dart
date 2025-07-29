import 'package:flutter/material.dart';
import '../../services/store_service.dart';
import '../../models/store.dart';
import '../../controllers/stock_controller.dart';

class StockTransferModal extends StatefulWidget {
  const StockTransferModal({Key? key}) : super(key: key);

  @override
  State<StockTransferModal> createState() => _StockTransferModalState();
}

class _StockTransferModalState extends State<StockTransferModal> {
  final _formKey = GlobalKey<FormState>();
  Store? _source;
  Store? _destination;
  String? _comment;
  int? _quantity;
  bool _loading = false;
  List<Store> _stores = [];
  final StoreService _storeService = StoreService();
  final StockController _stockController = StockController();

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    try {
      final stores = await _storeService.getStores();
      setState(() {
        _stores = stores.where((s) => s.isActive).toList();
      });
    } catch (e) {
      // Gérer l'erreur de récupération
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      final success = await _stockController.transferStock(
        productId: '', // À compléter selon le contexte d'appel
        fromStoreId: _source!.id,
        toStoreId: _destination!.id,
        quantity: _quantity!,
        reason: _comment,
      );
      setState(() => _loading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfert effectué avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du transfert')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.45 > 600
        ? 600.0
        : (screenWidth * 0.45 < 320 ? 320.0 : screenWidth * 0.45);
    final width = screenWidth < 600 ? screenWidth * 0.965 : dialogWidth;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: width,
        child: screenWidth < 600
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header compact
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7717E8), Color(0xFFB388FF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.compare_arrows,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Transfert de stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Formulaire modernisé (inputs 1/ligne)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<Store>(
                                value: _source,
                                items: _stores
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _source = v),
                                decoration: const InputDecoration(
                                  labelText: 'Magasin source',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (v) =>
                                    v == null ? 'Obligatoire' : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<Store>(
                                value: _destination,
                                items: _stores
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _destination = v),
                                decoration: const InputDecoration(
                                  labelText: 'Magasin destination',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null) return 'Obligatoire';
                                  if (v == _source)
                                    return 'Doit être différent du source';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantité à transférer',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Obligatoire';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0)
                                    return 'Quantité invalide';
                                  return null;
                                },
                                onChanged: (v) => _quantity = int.tryParse(v),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Commentaire (optionnel)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: 2,
                                onChanged: (v) => _comment = v,
                              ),
                              const SizedBox(height: 22),
                              Center(
                                child: Tooltip(
                                  message: 'Valider le transfert',
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7717E8),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(18),
                                      elevation: 6,
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.swap_horiz,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7717E8), Color(0xFFB388FF)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.compare_arrows, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Transfert de stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Card formulaire
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<Store>(
                                    value: _source,
                                    items: _stores
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _source = v),
                                    decoration: const InputDecoration(
                                      labelText: 'Magasin source',
                                      border: OutlineInputBorder(),
                                      isDense: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 18,
                                      ),
                                    ),
                                    validator: (v) =>
                                        v == null ? 'Obligatoire' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<Store>(
                                    value: _destination,
                                    items: _stores
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _destination = v),
                                    decoration: const InputDecoration(
                                      labelText: 'Magasin destination',
                                      border: OutlineInputBorder(),
                                      isDense: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 18,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null) return 'Obligatoire';
                                      if (v == _source)
                                        return 'Doit être différent du source';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantité à transférer',
                                border: OutlineInputBorder(),
                                isDense: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Obligatoire';
                                final n = int.tryParse(v);
                                if (n == null || n <= 0)
                                  return 'Quantité invalide';
                                return null;
                              },
                              onChanged: (v) => _quantity = int.tryParse(v),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Commentaire (optionnel)',
                                border: OutlineInputBorder(),
                                isDense: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                              ),
                              maxLines: 2,
                              onChanged: (v) => _comment = v,
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text('Annuler'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7717E8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Valider le transfert'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
