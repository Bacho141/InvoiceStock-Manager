import 'package:flutter/material.dart';

import '../../../providers/invoice_provider.dart';
import '../../../widgets/managementInvoice/mobile/invoice_card_mobile.dart';

class InvoiceListMobileView extends StatefulWidget {
  final InvoiceProvider provider;

  const InvoiceListMobileView({Key? key, required this.provider})
    : super(key: key);

  @override
  _InvoiceListMobileViewState createState() => _InvoiceListMobileViewState();
}

class _InvoiceListMobileViewState extends State<InvoiceListMobileView> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Vérifications de sécurité pour éviter les blocages
    if (!mounted) return;
    if (_isLoadingMore) return;
    if (widget.provider.isLoading) return;
    if (widget.provider.currentPage >= widget.provider.totalPages) return;

    // Vérifier si on est proche du bas (80% de défilement)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreInvoices();
    }
  }

  Future<void> _loadMoreInvoices() async {
    if (_isLoadingMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.provider.loadMoreInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context, widget.provider);
  }

  Widget _buildContent(BuildContext context, InvoiceProvider provider) {
    if (provider.isLoading && provider.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    if (provider.invoices.isEmpty) {
      return const Center(child: Text('Aucune facture trouvée.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: provider.invoices.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Si c'est le dernier élément et qu'on charge plus
        if (index == provider.invoices.length) {
          return _buildLoadingIndicator();
        }

        final invoice = provider.invoices[index];
        return InvoiceCardMobile(invoice: invoice);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
