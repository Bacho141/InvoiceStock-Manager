import 'package:flutter/material.dart';
import '../../../models/payment.dart';
import '../../../models/invoice.dart';
import '../../../services/payment_service.dart';
import 'add_payment_modal.dart';
import 'payment_card.dart';
import 'payment_summary_widget.dart';

class PaymentHistoryWidget extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback? onPaymentUpdated;

  const PaymentHistoryWidget({
    Key? key,
    required this.invoice,
    this.onPaymentUpdated,
  }) : super(key: key);

  @override
  State<PaymentHistoryWidget> createState() => _PaymentHistoryWidgetState();
}

class _PaymentHistoryWidgetState extends State<PaymentHistoryWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convertir l'historique de paiement existant dans la facture
      final payments = widget.invoice.paymentHistory
          .map(
            (ph) => Payment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              createdAt: ph.date,
              amount: ph.amount,
              method: PaymentMethod.fromString(ph.method),
              processedBy: null, // TODO: récupérer l'utilisateur par ID
            ),
          )
          .toList();

      // Optionnel: récupérer depuis l'API pour les données complètes
      try {
        final apiPayments = await _paymentService.getPaymentHistory(
          widget.invoice.id,
        );
        if (apiPayments.isNotEmpty) {
          payments.clear();
          payments.addAll(apiPayments);
        }
      } catch (e) {
        debugPrint(
          '[PaymentHistoryWidget] Erreur API, utilisation données locales: $e',
        );
      }

      if (mounted) {
        setState(() {
          _payments = payments.sortByDateDesc();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddPaymentModal() async {
    final remainingAmount = widget.invoice.total - widget.invoice.montantPaye;

    if (remainingAmount <= 0) {
      _showSuccessSnackBar('Cette facture est déjà entièrement payée');
      return;
    }

    final result = await showModalBottomSheet<Payment?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentModal(
        invoiceId: widget.invoice.id,
        remainingAmount: remainingAmount,
        onPaymentAdded: (payment) {
          Navigator.of(context).pop(payment);
        },
      ),
    );

    if (result != null) {
      await _loadPaymentHistory();
      widget.onPaymentUpdated?.call();
      _showSuccessSnackBar(
        'Paiement de ${result.formattedAmount} ajouté avec succès',
      );
    }
  }

  Future<void> _cancelPayment(Payment payment) async {
    final confirmed = await _showConfirmDialog(
      'Annuler le paiement',
      'Êtes-vous sûr de vouloir annuler ce paiement de ${payment.formattedAmount} ?',
    );

    if (confirmed) {
      try {
        await _paymentService.cancelPayment(
          invoiceId: widget.invoice.id,
          paymentId: payment.id,
          reason: 'Annulation demandée par l\'utilisateur',
        );

        await _loadPaymentHistory();
        widget.onPaymentUpdated?.call();
        _showSuccessSnackBar('Paiement annulé avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'annulation: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec résumé
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7717E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Color(0xFF7717E8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Historique des Paiements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            '${_payments.length} paiement(s) enregistré(s)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.invoice.montantPaye < widget.invoice.total)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _showAddPaymentModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7717E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                PaymentSummaryWidget(invoice: widget.invoice),
              ],
            ),
          ),

          // Contenu principal
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7717E8)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de l\'historique...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPaymentHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun paiement enregistré',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les paiements apparaîtront ici une fois ajoutés',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPaymentModal,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un paiement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7717E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return PaymentCard(
            payment: payment,
            onCancel: () => _cancelPayment(payment),
            showActions: payment.status != PaymentStatus.cancelled,
          );
        },
      ),
    );
  }
}
