import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import 'lead_activity_model.dart';
import 'lead_model.dart';
import 'lead_repository.dart';
import '../../core/log.dart';

/// Outcome of [LeadDetailController.saveCall].
enum SaveCallStatus { saved, invalid, failed }

class SaveCallResult {
  const SaveCallResult(this.status, [this.error]);

  final SaveCallStatus status;
  final AppError? error;
}

/// State for one lead's detail screen: the lead, its notes and tasks, the
/// "log a call" draft, and status/save actions.
class LeadDetailController extends ChangeNotifier {
  LeadDetailController({
    required this.leadName,
    CrmLead? initialLead,
    LeadRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? LeadRepository(),
       _clock = clock ?? DateTime.now,
       _lead = initialLead {
    _followUp = defaultFollowUp(_clock());
  }

  final String leadName;
  final LeadRepository _repository;
  final DateTime Function() _clock;

  CrmLead? _lead;
  List<LeadStatus> _statuses = const [];
  List<CrmNote> _notes = const [];
  List<CrmTask> _tasks = const [];
  bool _hasLoaded = false;
  bool _isLoading = false;
  AppError? _error;
  String? _updatingStatus;
  bool _isSaving = false;

  CallOutcome? _outcome;
  late DateTime _followUp;
  bool _showOutcomeError = false;
  _SaveProgress? _saveProgress;

  bool _disposed = false;

  /// Lead from the list while the full document loads, then the full one.
  CrmLead? get lead => _lead;
  List<LeadStatus> get statuses => _statuses;
  List<CrmNote> get notes => _notes;
  List<CrmTask> get tasks => _tasks;

  /// True once lead, notes and tasks have loaded successfully.
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => _isLoading;

  /// Error from the first load (shown as a full-screen error state).
  AppError? get error => _error;

  /// Status currently being saved, if any.
  String? get updatingStatus => _updatingStatus;
  bool get isSaving => _isSaving;
  CallOutcome? get outcome => _outcome;
  DateTime get followUp => _followUp;
  bool get showOutcomeError => _showOutcomeError;
  bool get createsFollowUp => _outcome != CallOutcome.wrongNumber;
  DateTime get now => _clock();

  LeadStatus? get currentStatus {
    for (final status in _statuses) {
      if (status.name == _lead?.status) return status;
    }
    return null;
  }

  /// The open task due soonest; tasks without a due date come last.
  CrmTask? get nextOpenTask {
    final open = _tasks.where((t) => t.isOpen).toList()
      ..sort((a, b) {
        final ad = a.dueDate, bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return open.isEmpty ? null : open.first;
  }

  /// Tomorrow at 10:00.
  static DateTime defaultFollowUp(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1, 10);

  /// First load: shows the skeleton, then content or the error state.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _notify();
    _error = await _fetchAll();
    _isLoading = false;
    _notify();
  }

  /// Pull-to-refresh: keeps current data visible; returns the error, if any.
  Future<AppError?> refresh() async {
    if (!_hasLoaded) {
      await load();
      return _error;
    }
    final error = await _fetchAll();
    _notify();
    return error;
  }

  Future<AppError?> _fetchAll() async {
    try {
      final results = await Future.wait<Object>([
        _repository.getLead(leadName),
        _repository.getNotes(leadName),
        _repository.getTasks(leadName),
      ]);
      _lead = results[0] as CrmLead;
      _notes = results[1] as List<CrmNote>;
      _tasks = results[2] as List<CrmTask>;
      _hasLoaded = true;
    } on AppException catch (e) {
      return e.error;
    }
    if (_statuses.isEmpty) {
      try {
        _statuses = await _repository.fetchStatuses();
      } on AppException catch (e) {
        // Chips stay hidden; the rest of the screen still works.
        logDebug('Loading lead statuses failed: ${e.error}');
      }
    }
    return null;
  }

  /// Saves the new status and reloads. Returns the error, if any.
  Future<AppError?> updateStatus(String status) async {
    if (_updatingStatus != null || status == _lead?.status) return null;
    _updatingStatus = status;
    _notify();
    try {
      await _repository.updateStatus(leadName, status);
    } on AppException catch (e) {
      _updatingStatus = null;
      _notify();
      return e.error;
    }
    await _fetchAll();
    _updatingStatus = null;
    _notify();
    return null;
  }

  void selectOutcome(CallOutcome outcome) {
    _outcome = outcome;
    _showOutcomeError = false;
    _notify();
  }

  void setFollowUp(DateTime value) {
    _followUp = value;
    _notify();
  }

  /// a) note, b) close open follow-up tasks, c) new follow-up unless the
  /// number is wrong, d) reload. Steps that succeeded are not repeated if the
  /// user retries the same draft after a failure.
  Future<SaveCallResult> saveCall(String note) async {
    if (_isSaving) return const SaveCallResult(SaveCallStatus.invalid);
    final outcome = _outcome;
    if (outcome == null) {
      _showOutcomeError = true;
      _notify();
      return const SaveCallResult(SaveCallStatus.invalid);
    }

    final text = note.trim();
    final followUp = outcome == CallOutcome.wrongNumber ? null : _followUp;
    final key = (outcome, text, followUp);
    if (_saveProgress?.key != key) _saveProgress = _SaveProgress(key);
    final progress = _saveProgress!;

    _isSaving = true;
    _notify();
    try {
      if (!progress.noteAdded) {
        await _repository.addNote(leadName, outcome.noteTitle, text);
        progress.noteAdded = true;
      }
      for (final task in _tasks) {
        if (!task.isOpen || !task.isFollowUp) continue;
        if (progress.completedTasks.contains(task.name)) continue;
        await _repository.completeTask(task.name);
        progress.completedTasks.add(task.name);
      }
      if (followUp != null && !progress.followUpAdded) {
        await _repository.addFollowUp(leadName, followUp, text);
        progress.followUpAdded = true;
      }
    } on AppException catch (e) {
      _isSaving = false;
      _notify();
      return SaveCallResult(SaveCallStatus.failed, e.error);
    }

    _saveProgress = null;
    _outcome = null;
    _showOutcomeError = false;
    _followUp = defaultFollowUp(_clock());
    await _fetchAll();
    _isSaving = false;
    _notify();
    return const SaveCallResult(SaveCallStatus.saved);
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

class _SaveProgress {
  _SaveProgress(this.key);

  final (CallOutcome, String, DateTime?) key;
  bool noteAdded = false;
  bool followUpAdded = false;
  final Set<String> completedTasks = {};
}
