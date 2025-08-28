import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';

class PeriodFilterDialog extends StatefulWidget {
  const PeriodFilterDialog({Key? key}) : super(key: key);

  @override
  _PeriodFilterDialogState createState() => _PeriodFilterDialogState();
}

class _PeriodFilterDialogState extends State<PeriodFilterDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedRadio = 0; // 0 for specific date, 1 for date range

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    _startDate = provider.startDate;
    _endDate = provider.endDate;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Sélectionner une période'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Périodes'),
                Tab(text: 'Personnalisé'),
              ],
            ),
            SizedBox(
              height: 210,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPredefinedPeriods(provider),
                  _buildCustomPeriod(provider),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_tabController.index == 1) {
              if (_selectedRadio == 0 && _startDate != null) {
                provider.setCustomPeriod(_startDate!, null);
              } else if (_selectedRadio == 1 && _startDate != null && _endDate != null) {
                provider.setCustomPeriod(_startDate!, _endDate);
              }
            }
            Navigator.of(context).pop();
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  Widget _buildPredefinedPeriods(InvoiceProvider provider) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Aujourd\'hui'),
          onTap: () {
            provider.setPeriodFilter('today');
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: const Text('Ce mois-ci'),
          onTap: () {
            provider.setPeriodFilter('this_month');
            Navigator.of(context).pop();
          },
        ),
        ListTile(
          title: const Text('Cette année'),
          onTap: () {
            provider.setPeriodFilter('this_year');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildCustomPeriod(InvoiceProvider provider) {
    return Column(
      children: [
        RadioListTile<int>(
          title: const Text('Date spécifique'),
          value: 0,
          groupValue: _selectedRadio,
          onChanged: (value) {
            setState(() {
              _selectedRadio = value!;
            });
          },
        ),
        ElevatedButton(
          onPressed: _selectedRadio == 0 ? () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _startDate = date;
              });
            }
          } : null,
          child: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Sélectionner une date'),
        ),
        RadioListTile<int>(
          title: const Text('Plage de dates'),
          value: 1,
          groupValue: _selectedRadio,
          onChanged: (value) {
            setState(() {
              _selectedRadio = value!;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _selectedRadio == 1 ? () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              } : null,
              child: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Début'),
            ),
            ElevatedButton(
              onPressed: _selectedRadio == 1 ? () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              } : null,
              child: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Fin'),
            ),
          ],
        ),
      ],
    );
  }
}
