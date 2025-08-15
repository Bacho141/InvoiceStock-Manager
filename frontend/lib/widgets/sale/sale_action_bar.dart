import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/cart_controller.dart';
import '../../layout/invoice_a5_layout.dart';
import '../../layout/invoice_pos_layout.dart';
import '../../layout/invoice_pos_mobile_layout.dart';
import '../../screens/sale/receipt_format_selector.dart' show ReceiptFormat, showReceiptFormatSelector;
import '../../services/invoice_service.dart';
import '../../utiles/number_to_words_fr.dart';
import '../../services/product_service.dart';
import '../../models/cart.dart';

class SaleActionBar extends StatefulWidget {
  final String? storeId;
  const SaleActionBar({Key? key, required this.storeId}) : super(key: key);

  @override
  State<SaleActionBar> createState() => _SaleActionBarState();
}

class _SaleActionBarState extends State<SaleActionBar> {
  String _selectedFormat = 'A5'; // Valeur par défaut

  Future<void> _showReceiptFormatSelector() async {
    final format = await showReceiptFormatSelector(
      context: context,
    );

    if (format == null) return; // L'utilisateur a annulé

    if (!mounted) return;

    setState(() {
      _selectedFormat = format == ReceiptFormat.a5 ? 'A5' : 'POS';
    });

    await _handleValidateInvoice();
  }

  Future<void> _handleValidateInvoice() async {
    await _createInvoiceWithStatus(null);
  }

  Future<void> _handleSetOnHold() async {
    await _createInvoiceWithStatus('en_attente');
  }

  Future<void> _createInvoiceWithStatus(String? status) async {
    debugPrint('[SALE_ACTION_BAR] Création facture avec statut: $status pour le magasin: ${widget.storeId}');
    final cart = CartController();
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    final selectedStoreId = widget.storeId;

    if (selectedStoreId == null || selectedStoreId == 'all') {
      if (!mounted) return;
      _showErrorDialog('Aucun magasin valide sélectionné. Veuillez sélectionner un magasin.');
      return;
    }

    if (cart.client?.id == null) {
      if (!mounted) return;
      _showErrorDialog('Veuillez sélectionner un client.');
      return;
    }

    if (currentUserId == null) {
      if (!mounted) return;
      _showErrorDialog('Utilisateur non trouvé.');
      return;
    }

    try {
      // Vérification de la disponibilité du stock pour chaque produit
      final productService = ProductService();
      for (var item in cart.items) {
        final availability = await productService.checkProductAvailability(
          selectedStoreId,
          item.product.id!,
          item.quantity,
        );

        if (!(availability['isAvailable'] as bool)) {
          if (!mounted) return;
          _showErrorDialog(
            'Stock insuffisant pour le produit "${item.product.name}". \n'
            'Quantité demandée: ${item.quantity}, \n'
            'Quantité disponible: ${availability['availableQuantity']}.',
          );
          return; // Arrête le processus
        }
      }

      final payload = {
        "client": cart.client?.id,
        "store": selectedStoreId,
        "user": currentUserId,
        "lines": cart.items
            .map((item) => {
                  "product": item.product.id,
                  "productName": item.product.name,
                  "quantity": item.quantity,
                  "unitPrice": item.product.sellingPrice,
                  "discount": item.discount ?? 0,
                  "totalLine": item.total,
                })
            .toList(),
        "total": cart.total,
        "totalInWords": numberToWordsFr(cart.total.toInt()),
        "discountTotal": cart.totalDiscount,
        "paymentMethod": cart.paymentMethod,
        "format": _selectedFormat,
        "montantPaye": cart.amountPaid,
        if (status != null) "status": status,
      };

      final invoiceData = await InvoiceService().createInvoice(payload);

      final newFacture = invoiceData['data'];
      final newFactureId = newFacture?['_id'];

      if (!mounted) return;
      cart.clear();

      if (status == 'en_attente') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La vente a été mise en attente.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        if (_selectedFormat == 'A5') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InvoiceA5Layout(facture: invoiceData['data']),
            ),
          );
        } else {
          final platform = Theme.of(context).platform;
          final isMobile = platform == TargetPlatform.android || platform == TargetPlatform.iOS;

          if (isMobile) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoicePOSMobileLayout(facture: invoiceData['data']),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoicePOSLayout(facture: invoiceData['data']),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[API] Erreur création facture: $e');
      if (!mounted) return;
      _showErrorDialog('Erreur lors de la création de la facture: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                label: 'Mettre en attente',
                icon: Icons.pause_circle_outline,
                color: const Color(0xFF7717E8),
                onPressed: _handleSetOnHold,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                label: 'Annuler la vente',
                icon: Icons.cancel_outlined,
                color: Colors.redAccent,
                outlined: true,
                onPressed: cart.clear,
              ),
              const SizedBox(width: 24),
              AnimatedBuilder(
                animation: cart,
                builder: (context, child) {
                  final isClientSelected = cart.client != null;
                  final isStoreSelected = widget.storeId != null &&
                      widget.storeId!.isNotEmpty &&
                      widget.storeId != 'all';
                  return Tooltip(
                    message: isStoreSelected
                        ? ''
                        : 'Veuillez sélectionner un magasin spécifique pour valider la facture.',
                    child: _ActionButton(
                      label: 'Valider la Facture',
                      icon: Icons.attach_money,
                      color: const Color(0xFF43A047),
                      onPressed: (isClientSelected && isStoreSelected)
                          ? _showReceiptFormatSelector
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          );

    return outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: buttonStyle,
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: buttonStyle,
          );
  }
}