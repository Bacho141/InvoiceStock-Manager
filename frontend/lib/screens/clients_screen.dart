import 'package:flutter/material.dart';
import '../layout/main_layout.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7717E8),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7717E8),
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Clients'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Créances'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildClientsTab(), _buildCreancesTab()],
            ),
          ),
        ],
      ),
    );

    return MainLayout(
      currentRoute: '/clients',
      pageTitle: '👥 Clients & Créances',
      child: content,
    );
  }

  Widget _buildClientsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 80, color: Color(0xFF7717E8)),
          SizedBox(height: 24),
          Text(
            'Gestion des clients (test)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Ici vous pourrez gérer la liste des clients.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCreancesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Color(0xFF7717E8),
          ),
          SizedBox(height: 24),
          Text(
            'Gestion des créances (test)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Ici vous pourrez suivre et gérer les créances clients.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
