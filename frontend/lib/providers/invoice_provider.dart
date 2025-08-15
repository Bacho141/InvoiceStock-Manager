import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/invoice_service.dart';
import '../models/invoice.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _invoiceService;
  String? _storeId;

  bool _isLoading = true;
  List<Invoice> _invoices = [];
  String? _error;

  // Filters
  String? _statusFilter;
  String? _periodFilter = 'this_month';
  String? _searchTerm;
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalInvoices = 0;
  final int _pageSize = 10;

  // Selection
  final Set<String> _selectedInvoices = {};

  // Getters
  bool get isLoading => _isLoading;
  List<Invoice> get invoices => _invoices;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get periodFilter => _periodFilter;
  String? get searchTerm => _searchTerm;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalInvoices => _totalInvoices;
  int get pageSize => _pageSize;
  Set<String> get selectedInvoices => _selectedInvoices;
  bool get areAllSelected => _invoices.isNotEmpty && _selectedInvoices.length == _invoices.length;

  String get periodFilterText {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}';
    } else if (_startDate != null) {
      return DateFormat('dd/MM/yyyy').format(_startDate!);
    } else {
      switch (_periodFilter) {
        case 'today':
          return 'Aujourd\'hui';
        case 'this_month':
          return 'Ce mois-ci';
        case 'this_year':
          return 'Cette année';
        default:
          return 'Toutes';
      }
    }
  }

  InvoiceProvider(this._invoiceService) {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _storeId = prefs.getString('selected_store_id');
    
    if (_storeId != null && _storeId!.isNotEmpty) {
      await loadInvoices();
    } else {
      _isLoading = false;
      _error = "Aucun magasin n'est sélectionné.";
      notifyListeners();
    }
  }

  Future<void> loadInvoices() async {
    if (_storeId == null) {
      _error = "Erreur: ID du magasin non disponible.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _selectedInvoices.clear(); // Clear selection on fetch
    notifyListeners();

    try {
      final filters = <String, String>{
        'storeId': _storeId!,
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
      };
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        filters['status'] = _statusFilter!;
      }
      if (_periodFilter != null && _periodFilter!.isNotEmpty) {
        filters['period'] = _periodFilter!;
      }
      if (_searchTerm != null && _searchTerm!.isNotEmpty) {
        filters['search'] = _searchTerm!;
      }
      if (_startDate != null) {
        filters['startDate'] = _startDate!.toIso8601String();
      }
      if (_endDate != null) {
        filters['endDate'] = _endDate!.toIso8601String();
      }

      final response = await _invoiceService.getInvoices(filters: filters);
      final invoicesData = List<Map<String, dynamic>>.from(response['data'] ?? []);
      _invoices = invoicesData.map((data) => Invoice.fromJson(data)).toList();
      
      _totalInvoices = response['total'] ?? 0;
      _totalPages = response['totalPages'] ?? 1;
      _currentPage = response['currentPage'] ?? 1;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    _currentPage = 1;
    loadInvoices();
  }

  void setPeriodFilter(String? period) {
    _periodFilter = period;
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    loadInvoices();
  }

  void setCustomPeriod(DateTime start, DateTime? end) {
    _periodFilter = null;
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    loadInvoices();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    _currentPage = 1;
    loadInvoices();
  }

  void changePage(int newPage) {
    if (newPage > 0 && newPage <= _totalPages) {
      _currentPage = newPage;
      loadInvoices();
    }
  }

  void selectInvoice(String invoiceId, bool isSelected) {
    if (isSelected) {
      _selectedInvoices.add(invoiceId);
    } else {
      _selectedInvoices.remove(invoiceId);
    }
    notifyListeners();
  }

  void selectAll(bool isSelected) {
    if (isSelected) {
      _selectedInvoices.addAll(_invoices.map((inv) => inv.id));
    } else {
      _selectedInvoices.clear();
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchTerm = '';
    _statusFilter = '';
    _periodFilter = '';
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    notifyListeners();
    loadInvoices();
  }

  void resetFilters() {
    _searchTerm = '';
    _statusFilter = '';
    _periodFilter = '';
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    _currentPage = 1;
    await loadInvoices();
  }
}