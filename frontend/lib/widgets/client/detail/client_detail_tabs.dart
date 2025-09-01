// lib/widgets/client/detail/client_detail_tabs.dart
import 'package:flutter/material.dart';
import '../../../models/client.dart';
import '../../../controllers/client_controller.dart';
import '../../../controllers/creance_controller.dart';
import 'tabs/client_info_tab.dart';
import 'tabs/client_financial_tab.dart';
import 'tabs/client_history_tab.dart';
import 'tabs/client_creances_tab.dart';

class ClientDetailTabs extends StatelessWidget {
  final Client client;
  final ClientController clientController;
  final CreanceController creanceController;
  final TabController tabController;
  final VoidCallback onRefresh;

  const ClientDetailTabs({
    Key? key,
    required this.client,
    required this.clientController,
    required this.creanceController,
    required this.tabController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: tabController,
      labelColor: const Color(0xFF7717E8),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF7717E8),
      tabs: const [
        Tab(icon: Icon(Icons.info), text: 'Informations'),
        Tab(icon: Icon(Icons.analytics), text: 'Financier'),
        Tab(icon: Icon(Icons.history), text: 'Historique'),
        Tab(icon: Icon(Icons.account_balance), text: 'Créances'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: [
        ClientInfoTab(client: client),
        ClientFinancialTab(client: client),
        ClientHistoryTab(client: client),
        ClientCreancesTab(
          client: client,
          creanceController: creanceController,
        ),
      ],
    );
  }
}