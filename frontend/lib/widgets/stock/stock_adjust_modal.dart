import 'package:flutter/material.dart';
import '../../models/store.dart';
import '../../models/stock.dart';
import '../../controllers/stock_controller.dart';

class StockAdjustModal extends StatefulWidget {
  final Store? store;
  final List<Stock> stocks;
  final VoidCallback? onSave;
  const StockAdjustModal({
    Key? key,
    required this.store,
    required this.stocks,
    this.onSave,
  }) : super(key: key);

  @override
  State<StockAdjustModal> createState() => _StockAdjustModalState();
}

class _StockAdjustModalState extends State<StockAdjustModal> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String _type = 'entrée';
  int? _quantite;
  String? _raison;
  bool _loading = false;
  final StockController _controller = StockController();

  @override
  void initState() {
    super.initState();
    if (widget.stocks.isNotEmpty) {
      _selectedProductId = widget.stocks.first.productId;
    }
  }

  int get _stockActuel {
    final stock = widget.stocks.firstWhere(
      (s) => s.productId == _selectedProductId,
      orElse: () => widget.stocks.isNotEmpty
          ? widget.stocks.first
          : Stock(
              id: '',
              productId: '',
              storeId: '',
              quantity: 0,
              minQuantity: 0,
              isActive: true,
              lastUpdated: DateTime.now(),
            ),
    );
    return stock.quantity;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);
      final storeId = widget.store?.id;
      final productId = _selectedProductId;
      final quantity = _quantite;
      final reason = _raison ?? '';
      if (storeId == null || productId == null || quantity == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs.')),
        );
        return;
      }
      // Calculer la nouvelle quantité selon le type
      int newQuantity = _stockActuel;
      if (_type == 'entrée') {
        newQuantity += quantity;
      } else {
        newQuantity -= quantity;
      }
      final success = await _controller.adjustStock(
        storeId,
        productId,
        newQuantity,
        reason,
      );
      setState(() => _loading = false);
      if (success) {
        Navigator.of(context).pop();
        if (widget.onSave != null) widget.onSave!();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajustement enregistré !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ${_controller.error ?? 'Ajustement impossible'}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.35 > 420
        ? 420.0
        : (screenWidth * 0.35 < 300 ? 300.0 : screenWidth * 0.35);
    final width = screenWidth < 600 ? screenWidth * 0.965 : dialogWidth;
    final produits = widget.stocks;
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
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'Nouvel Ajustement',
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
                              DropdownButtonFormField<String>(
                                value: _selectedProductId,
                                items: produits
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p.productId,
                                        child: Text(p.productName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedProductId = v),
                                decoration: const InputDecoration(
                                  labelText: 'Produit',
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
                              Text(
                                'Stock actuel : $_stockActuel',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              RadioListTile<String>(
                                value: 'entrée',
                                groupValue: _type,
                                onChanged: (v) => setState(() => _type = v!),
                                title: const Text('Entrée de Stock'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                              RadioListTile<String>(
                                value: 'sortie',
                                groupValue: _type,
                                onChanged: (v) => setState(() => _type = v!),
                                title: const Text('Sortie/Perte'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Quantité à ajuster',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Obligatoire';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0)
                                    return 'Quantité invalide';
                                  return null;
                                },
                                onChanged: (v) => _quantite = int.tryParse(v),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Raison / Référence',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (v) => _raison = v,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Obligatoire'
                                    : null,
                              ),
                              const SizedBox(height: 22),
                              Center(
                                child: Tooltip(
                                  message: 'Enregistrer le mouvement',
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
                                            Icons.save,
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
                        const Icon(Icons.edit, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Nouvel Ajustement de Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
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
                        horizontal: 14,
                        vertical: 18,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedProductId,
                              items: produits
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.productId,
                                      child: Text(p.productName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProductId = v),
                              decoration: const InputDecoration(
                                labelText: 'Produit',
                                border: OutlineInputBorder(),
                                isDense: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) =>
                                  v == null ? 'Obligatoire' : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Stock actuel : $_stockActuel',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF7717E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    value: 'entrée',
                                    groupValue: _type,
                                    onChanged: (v) =>
                                        setState(() => _type = v!),
                                    title: const Text('Entrée de Stock'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    value: 'sortie',
                                    groupValue: _type,
                                    onChanged: (v) =>
                                        setState(() => _type = v!),
                                    title: const Text('Sortie/Perte'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Quantité à ajuster',
                                border: OutlineInputBorder(),
                                isDense: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Obligatoire';
                                final n = int.tryParse(v);
                                if (n == null || n <= 0)
                                  return 'Quantité invalide';
                                return null;
                              },
                              onChanged: (v) => _quantite = int.tryParse(v),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Raison / Référence',
                                border: OutlineInputBorder(),
                                isDense: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (v) => _raison = v,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Obligatoire' : null,
                            ),
                            const SizedBox(height: 24),
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
                                      : const Text('Enregistrer le Mouvement'),
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
