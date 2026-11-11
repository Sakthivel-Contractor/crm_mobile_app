import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../leads/lead_model.dart';
import '../leads/lead_repository.dart';
import 'dashboard_model.dart';
import 'dashboard_repository.dart';
import '../../core/log.dart';

/// State for the Dashboard tab.
class DashboardController extends ChangeNotifier {
  DashboardController({
    DashboardRepository? repository,
    LeadRepository? leadRepository,
    DateTime Function()? clock,
  }) : _repository = repository ?? DashboardRepository(),
       _leads = leadRepository ?? LeadRepository(),
       _clock = clock ?? DateTime.now;

  final DashboardRepository _repository;
  final LeadRepository _leads;
  final DateTime Function() _clock;

  /// Districts shown before the rest fold into "Other".
  static const int topDistricts = 6;

  DashboardPeriod _period = DashboardPeriod.month;
  PeriodRange? _customRange;
  DashboardData? _data;
  bool _isLoading = false;
  AppError? _error;
  DateTime? _updatedAt;
  List<LeadStatus> _statuses = const [];
  int _generation = 0;
  bool _disposed = false;

  DashboardPeriod get period => _period;
  PeriodRange? get customRange => _customRange;
  DashboardData? get data => _data;
  bool get hasLoaded => _data != null;

  /// True while loading with nothing to show yet (skeleton).
  bool get isLoading => _isLoading && _data == null;
  AppError? get error => _error;
  DateTime? get updatedAt => _updatedAt;
  DateTime get now => _clock();

  PeriodRange get range => _period == DashboardPeriod.custom
      ? (_customRange ?? PeriodRange.of(DashboardPeriod.month, _clock()))
      : PeriodRange.of(_period, _clock());

  /// Funnel bars: every status in board order.
  List<GroupCount> get funnel =>
      _data == null ? const [] : funnelOrder(_data!.byStatus, _data!.statuses);

  List<GroupCount>? get bySource =>
      _data?.bySource == null ? null : sortByCount(_data!.bySource!);

  List<GroupCount>? get byDistrict => _data?.byDistrict == null
      ? null
      : topWithOther(_data!.byDistrict!, topDistricts);

  LeadStatus? statusNamed(String? name) {
    for (final s in _data?.statuses ?? const <LeadStatus>[]) {
      if (s.name == name) return s;
    }
    return null;
  }

  void setPeriod(DashboardPeriod period) {
    if (period == _period) return;
    _period = period;
    refresh();
  }

  void setCustomRange(PeriodRange range) {
    _period = DashboardPeriod.custom;
    _customRange = range;
    refresh();
  }

  /// First load (or retry): skeleton until data arrives.
  Future<void> load() async {
    if (_data == null) {
      _isLoading = true;
      _error = null;
      _notify();
    }
    await refresh();
  }

  /// Reloads everything in parallel; current data stays visible. Returns the
  /// error if the core numbers (total count) failed.
  Future<AppError?> refresh() async {
    final generation = ++_generation;
    final range = this.range;
    final now = _clock();
    _isLoading = true;
    _notify();

    AppError? error;
    try {
      final results = await Future.wait<Object?>([
        _repository.totalLeads(range),
        _optional(_repository.leadsByStatus(range)),
        _optional(_repository.leadsBySource(range)),
        _optional(_repository.leadsByDistrict(range)),
        _optional(_repository.siteVisits(range)),
        _optional(_repository.callsLogged(range)),
        _optional(_repository.overdueFollowUps(now)),
        if (_statuses.isEmpty) _optional(_leads.fetchStatuses()),
      ]);
      if (generation != _generation) return null;
      if (results.length > 7 && results[7] != null) {
        _statuses = results[7] as List<LeadStatus>;
      }
      _data = DashboardData(
        totalLeads: results[0] as int,
        byStatus: (results[1] as List<GroupCount>?) ?? const [],
        bySource: results[2] as List<GroupCount>?,
        byDistrict: results[3] as List<GroupCount>?,
        siteVisits: results[4] as int?,
        callsLogged: results[5] as int?,
        overdueFollowUps: results[6] as int?,
        statuses: _statuses,
      );
      _updatedAt = _clock();
    } on AppException catch (e) {
      if (generation != _generation) return null;
      error = e.error;
    }
    _error = error;
    _isLoading = false;
    _notify();
    return error;
  }

  /// Optional sections: a missing doctype/field (or any failure) → null.
  static Future<T?> _optional<T>(Future<T> request) async {
    try {
      return await request;
    } on AppException catch (e) {
      logDebug('Dashboard optional query failed: ${e.error}');
      return null;
    }
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
