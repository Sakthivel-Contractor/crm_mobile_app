import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import 'visit_model.dart';
import 'visit_repository.dart';

class VisitsController extends ChangeNotifier {
  VisitsController({VisitRepository? repository})
      : _repository = repository ?? VisitRepository();

  final VisitRepository _repository;

  List<SiteVisit> _visits = const [];
  bool _isLoading = false;
  AppError? _error;
  String _statusFilter = 'All';
  String _searchTerm = '';

  List<SiteVisit> get visits => _visits;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  String get statusFilter => _statusFilter;
  String get searchTerm => _searchTerm;

  void setFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }

  void search(String term) {
    _searchTerm = term;
    refresh();
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      _visits = await _repository.fetchVisits(
        status: _statusFilter == 'All' ? null : _statusFilter,
        search: _searchTerm,
      );
      _error = null;
    } on AppException catch (e) {
      _error = e.error;
    } catch (_) {
      _error = AppError.unknown;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String name, String newStatus) async {
    try {
      await _repository.updateStatus(name, newStatus);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}
