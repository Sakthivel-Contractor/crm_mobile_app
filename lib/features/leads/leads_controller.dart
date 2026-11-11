import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import 'lead_model.dart';
import 'lead_repository.dart';
import '../../core/log.dart';

/// State for the Leads tab: filters, paged items and loading/error flags.
class LeadsController extends ChangeNotifier {
  LeadsController({
    LeadRepository? repository,
    this.pageLength = LeadRepository.defaultPageLength,
  }) : _repository = repository ?? LeadRepository();

  final LeadRepository _repository;
  final int pageLength;

  static const Duration searchDebounce = Duration(milliseconds: 300);

  String _search = '';
  String? _status;
  String? _source;
  String? _district;
  List<CrmLead> _items = const [];
  List<LeadStatus> _statuses = const [];
  int _page = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  AppError? _error;
  AppError? _loadMoreError;

  Timer? _debounce;
  bool _disposed = false;

  /// Bumped on every new first-page load so stale responses are dropped.
  int _generation = 0;

  String get search => _search;
  String? get status => _status;
  String? get source => _source;
  String? get district => _district;
  List<CrmLead> get items => _items;
  List<LeadStatus> get statuses => _statuses;
  int get page => _page;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  /// Error from the last first-page load.
  AppError? get error => _error;

  /// Error from the last next-page load.
  AppError? get loadMoreError => _loadMoreError;

  Future<void> init() => Future.wait([_loadStatuses(), refresh()]);

  /// Reload from page 1. With [keepItems] (pull-to-refresh) the current list
  /// stays visible until the new page arrives.
  Future<void> refresh({bool keepItems = false}) async {
    final generation = ++_generation;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _loadMoreError = null;
    if (!keepItems) _items = const [];
    _notify();

    try {
      final rows = await _repository.fetchLeads(
        search: _search,
        status: _status,
        source: _source,
        district: _district,
        start: 0,
        pageLength: pageLength,
      );
      if (generation != _generation) return;
      _items = rows;
      _page = 1;
      _hasMore = rows.length >= pageLength;
    } on AppException catch (e) {
      if (generation != _generation) return;
      _error = e.error;
    }
    _isLoading = false;
    _notify();
  }

  /// Retry after a first-page error; also reloads statuses if they failed.
  Future<void> retry() =>
      Future.wait([if (_statuses.isEmpty) _loadStatuses(), refresh()]);

  /// Load the next page. Safe to call repeatedly (e.g. on every scroll).
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (_items.isEmpty || _loadMoreError != null) return;

    final generation = _generation;
    _isLoadingMore = true;
    _notify();

    try {
      final rows = await _repository.fetchLeads(
        search: _search,
        status: _status,
        source: _source,
        district: _district,
        start: _items.length,
        pageLength: pageLength,
      );
      if (generation != _generation) return;
      // Offset paging can repeat a row if leads changed between requests.
      final seen = {for (final lead in _items) lead.name};
      _items = [..._items, ...rows.where((lead) => seen.add(lead.name))];
      _page++;
      _hasMore = rows.length >= pageLength;
    } on AppException catch (e) {
      if (generation != _generation) return;
      _loadMoreError = e.error;
    }
    _isLoadingMore = false;
    _notify();
  }

  void retryLoadMore() {
    _loadMoreError = null;
    loadMore();
  }

  /// Debounced search; an empty [query] applies immediately.
  void setSearch(String query) {
    final term = query.trim();
    _debounce?.cancel();
    if (term == _search) return;
    if (term.isEmpty) {
      _search = '';
      refresh();
      return;
    }
    _debounce = Timer(searchDebounce, () {
      _search = term;
      refresh();
    });
  }

  /// Replaces all filters at once (e.g. from a dashboard bar) and reloads.
  /// Clears the search so the result matches what was tapped.
  void applyFilter({String? status, String? source, String? district}) {
    _debounce?.cancel();
    _search = '';
    _status = status;
    _source = source;
    _district = district;
    refresh();
  }

  void clearSource() {
    if (_source == null) return;
    _source = null;
    refresh();
  }

  void clearDistrict() {
    if (_district == null) return;
    _district = null;
    refresh();
  }

  /// null shows all statuses.
  void setStatus(String? status) {
    if (status == _status) return;
    _status = status;
    refresh();
  }

  LeadStatus? statusNamed(String? name) {
    if (name == null) return null;
    for (final status in _statuses) {
      if (status.name == name) return status;
    }
    return null;
  }

  Future<void> _loadStatuses() async {
    try {
      _statuses = await _repository.fetchStatuses();
      _notify();
    } on AppException catch (e) {
      // Chips fall back to "All" only; the list shows its own error.
      logDebug('Loading lead statuses failed: ${e.error}');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
