import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../leads/lead_activity_model.dart';
import '../leads/lead_model.dart';
import 'today_model.dart';
import 'today_repository.dart';

/// null = all items.
typedef TodayFilter = TodayItemType?;

/// State for the Today tab and its bottom-nav badge.
class TodayController extends ChangeNotifier {
  TodayController({TodayRepository? repository, DateTime Function()? clock})
    : _repository = repository ?? TodayRepository(),
      _clock = clock ?? DateTime.now;

  final TodayRepository _repository;
  final DateTime Function() _clock;

  List<TodayItem> _items = const [];
  TodayFilter _filter;
  bool _hasLoaded = false;
  bool _isLoading = false;
  AppError? _error;
  Future<AppError?>? _inFlight;
  bool _disposed = false;

  List<TodayItem> get items => _items;
  TodayFilter get filter => _filter;
  bool get hasLoaded => _hasLoaded;

  /// True while the first load (skeleton) is running.
  bool get isLoading => _isLoading && !_hasLoaded;

  /// Error from the last load, shown full-screen until data has loaded once.
  AppError? get error => _error;
  DateTime get now => _clock();

  List<TodayItem> get visibleItems => _filter == null
      ? _items
      : _items.where((item) => item.type == _filter).toList();

  int count(TodayItemType type) => _items.where((i) => i.type == type).length;
  int get total => _items.length;

  /// Overdue + due today — the bottom-nav badge.
  int get pendingCalls =>
      count(TodayItemType.overdue) + count(TodayItemType.dueToday);

  void setFilter(TodayFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _notify();
  }

  /// First load or retry: shows the skeleton until data arrives.
  Future<void> load() async {
    if (!_hasLoaded) {
      _isLoading = true;
      _error = null;
      _notify();
    }
    await refresh();
  }

  /// Reloads while keeping current items visible. Concurrent calls (tab
  /// switch + pull-to-refresh) share one request. Returns the error, if any.
  Future<AppError?> refresh() => _inFlight ??= _fetch().whenComplete(() {
    _inFlight = null;
  });

  Future<AppError?> _fetch() async {
    final now = _clock();
    AppError? error;
    try {
      final results = await Future.wait<Object>([
        _repository.fetchDueTasks(now),
        _repository.fetchNewLeads(),
      ]);
      final tasks = results[0] as List<CrmTask>;
      final newLeads = results[1] as List<CrmLead>;
      final names = tasks.map((t) => t.referenceDocname).whereType<String>();
      final leadsByName = names.isEmpty
          ? const <String, CrmLead>{}
          : await _repository.fetchLeadsByName(names);

      _items = buildTodayItems(
        tasks: tasks,
        leadsByName: leadsByName,
        newLeads: newLeads,
        now: now,
      );
      _hasLoaded = true;
    } on AppException catch (e) {
      error = e.error;
    }
    _error = error;
    _isLoading = false;
    _notify();
    return error;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
