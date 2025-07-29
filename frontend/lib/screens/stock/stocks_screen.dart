import 'package:flutter/material.dart';
import '../../layout/main_layout.dart';
import '../../widgets/stock/stock_indicators.dart';
import '../../widgets/stock/stock_filters.dart';
import '../../widgets/stock/stock_table.dart';
import '../../widgets/stock/stock_adjust_modal.dart';
import '../../controllers/stock_controller.dart';
import '../../models/stock.dart';
import '../../widgets/store_selector.dart';
import '../../models/store.dart';

class StocksScreen extends StatefulWidget {
  final Store? currentStore;
  const StocksScreen({Key? key, this.currentStore}) : super(key: key);

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final StockController _controller = StockController();
  int _buildCount = 0;
  Store? get _selectedStore => widget.currentStore;
  String? get _selectedStoreId => _selectedStore?.id;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[STOCKS_SCREEN][initState] currentStore: ${widget.currentStore?.id} - ${widget.currentStore?.name}',
    );
    _loadAll();
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStore?.id != widget.currentStore?.id) {
      debugPrint(
        '[STOCKS_SCREEN][didUpdateWidget] currentStore changé: ${widget.currentStore?.id} - ${widget.currentStore?.name}',
      );
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    final storeId = _selectedStoreId;
    debugPrint(
      '[STOCKS_SCREEN][_loadAll] storeId utilisé: ${storeId ?? 'ALL'}',
    );
    debugPrint('[STOCKS_SCREEN][_loadAll] Début du chargement des données...');

    try {
      if (storeId == null || storeId == 'all') {
        debugPrint('[STOCKS_SCREEN][_loadAll] Chargement données globales');
        await Future.wait([
          _controller.loadStocks(null),
          _controller.loadIndicators(null),
          _controller.loadStockAlerts(null),
        ]);
      } else {
        debugPrint(
          '[STOCKS_SCREEN][_loadAll] Chargement données magasin: $storeId',
        );
        await Future.wait([
          _controller.loadStocks(storeId),
          _controller.loadIndicators(storeId),
          _controller.loadStockAlerts(storeId),
        ]);
      }

      debugPrint(
        '[STOCKS_SCREEN][_loadAll] Chargement terminé - stocks: ${_controller.stocks.length}, indicateurs: ${_controller.indicators}, alertes: ${_controller.alerts.length}',
      );
      debugPrint(
        '[STOCKS_SCREEN][_loadAll] Indicateurs détaillés: ${_controller.indicators.toString()}',
      );
      debugPrint(
        '[STOCKS_SCREEN][_loadAll] Erreurs: stocks=${_controller.error}, alertes=${_controller.alertError}',
      );
    } catch (e, stackTrace) {
      debugPrint('[STOCKS_SCREEN][_loadAll] Erreur lors du chargement: $e');
      debugPrint('[STOCKS_SCREEN][_loadAll] Stack trace: $stackTrace');
    }

    setState(() {});
  }

  Future<void> _loadStocks() async {
    debugPrint(
      '[STOCKS_SCREEN][_loadStocks] storeId: ${_selectedStoreId ?? 'ALL'}',
    );
    await _controller.loadStocks(_selectedStoreId);
    debugPrint(
      '[STOCKS_SCREEN][_loadStocks] stocks chargés: ${_controller.stocks.length}',
    );
    setState(() {});
  }

  Future<void> _loadAlerts() async {
    debugPrint(
      '[STOCKS_SCREEN][_loadAlerts] storeId: ${_selectedStoreId ?? 'ALL'}',
    );
    await _controller.loadStockAlerts(_selectedStoreId);
    debugPrint(
      '[STOCKS_SCREEN][_loadAlerts] alertes chargées: ${_controller.alerts.length}',
    );
    setState(() {});
  }

  void _openAdjustModal() {
    showDialog(
      context: context,
      builder: (_) => StockAdjustModal(
        store: widget.currentStore,
        stocks: _controller.stocks,
        onSave: _loadAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint(
      '[STOCKS_SCREEN][build] buildCount: $_buildCount, currentStore: ${widget.currentStore?.id} - ${widget.currentStore?.name}',
    );
    debugPrint(
      '[STOCKS_SCREEN][build] États: isLoadingStocks=${_controller.isLoadingStocks}, isLoadingIndicators=${_controller.isLoadingIndicators}, isLoadingAlerts=${_controller.isLoadingAlerts}',
    );
    debugPrint(
      '[STOCKS_SCREEN][build] Données: stocks=${_controller.stocks.length}, indicateurs=${_controller.indicators.length}, alertes=${_controller.alerts.length}',
    );
    debugPrint(
      '[STOCKS_SCREEN][build] Erreurs: error=${_controller.error}, alertError=${_controller.alertError}',
    );

    Widget content;
    if (_controller.isLoadingStocks ||
        _controller.isLoadingIndicators ||
        _controller.isLoadingAlerts) {
      debugPrint('[STOCKS_SCREEN][build] Affichage loading...');
      content = const Center(child: CircularProgressIndicator());
    } else if (_controller.error != null) {
      debugPrint(
        '[STOCKS_SCREEN][build] Affichage erreur: ${_controller.error}',
      );
      content = Center(child: Text('Erreur : ${_controller.error}'));
    } else {
      debugPrint('[STOCKS_SCREEN][build] Affichage contenu normal');
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateurs clés dynamiques
            if (_controller.indicators.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              StockIndicators(indicators: _controller.indicators),
            const SizedBox(height: 24),
            // Affichage des alertes
            if (_controller.isLoadingAlerts)
              const Center(child: CircularProgressIndicator())
            else if (_controller.alertError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEB5757),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.error, color: Color(0xFFEB5757)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Erreur lors du chargement des alertes.',
                        style: TextStyle(
                          color: Color(0xFFEB5757),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_controller.alerts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF2994A),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF2994A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Alertes de stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._controller.alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              alert.type == 'rupture'
                                  ? Icons.error
                                  : Icons.warning,
                              color: alert.type == 'rupture'
                                  ? Color(0xFFEB5757)
                                  : Color(0xFFF2994A),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                alert.message,
                                style: TextStyle(
                                  color: alert.type == 'rupture'
                                      ? Color(0xFFEB5757)
                                      : Color(0xFFF2994A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Barre de filtres
            StockFilters(onNewAdjust: _openAdjustModal),
            const SizedBox(height: 24),
            // Contenu principal : tableau et widget côte à côte sur desktop
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 1200;
                if (isMobile) {
                  return Column(
                    children: [
                      // Tableau/liste des stocks dynamiques
                      StockTable(stocks: _controller.stocks),
                      const SizedBox(height: 32),
                      _buildStockManagementWidget(),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: StockTable(stocks: _controller.stocks),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildStockManagementWidget()),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    }

    return content;
  }

  Widget _buildStockManagementWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7717E8).withOpacity(0.05),
            const Color(0xFF7717E8).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7717E8).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7717E8).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7717E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF7717E8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Gestion des Stocks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            'Vous êtes sur la page de gestion des stocks.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Box d'information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7717E8).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: const Color(0xFF7717E8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Fonctionnalités',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cette page permet de gérer les niveaux de stock et les alertes.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF7717E8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Actions rapides
          const Text(
            'Actions Rapides',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Nouveau',
                  onTap: _openAdjustModal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Transférer',
                  onTap: () {
                    // TODO: Implémenter la logique de transfert
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7717E8).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7717E8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7717E8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
