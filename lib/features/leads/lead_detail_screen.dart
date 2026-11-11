import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../core/contact_links.dart';
import '../../core/screen_security.dart';
import '../../l10n/app_localizations.dart';
import '../auth/sign_out.dart';
import 'lead_detail_controller.dart';
import 'lead_model.dart';
import 'lead_status_style.dart';
import 'widgets/lead_detail_sections.dart';

class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({
    super.key,
    required this.lead,
    this.onLeadChanged,
    this.controller,
  });

  /// The lead from the list; the full document is loaded from the server.
  final CrmLead lead;

  /// Called after the status changes or a call is logged, so the list can
  /// refresh.
  final VoidCallback? onLeadChanged;

  /// Injectable for tests; created internally otherwise.
  final LeadDetailController? controller;

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late final LeadDetailController _controller =
      widget.controller ??
      LeadDetailController(
        leadName: widget.lead.name,
        initialLead: widget.lead,
      );
  final _noteController = TextEditingController();

  /// FLAG_SECURE was turned on by this screen (Profile setting).
  bool _secured = false;

  @override
  void initState() {
    super.initState();
    if (ScreenSecurity.instance.blockOnLeadDetail) {
      _secured = true;
      ScreenSecurity.setSecure(true);
    }
    _controller.load();
  }

  @override
  void dispose() {
    if (_secured) ScreenSecurity.setSecure(false);
    _noteController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(Uri? uri) async {
    if (uri == null || !await openExternal(uri)) {
      if (mounted) _snack(_l10n.couldNotOpenApp);
    }
  }

  Future<void> _refresh() async {
    final error = await _controller.refresh();
    if (error != null && mounted) _snack(appErrorMessage(_l10n, error));
  }

  Future<void> _changeStatus(String status) async {
    if (status == _controller.lead?.status) return;
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeStatusConfirm(localizedStatus(l10n, status))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await _controller.updateStatus(status);
    if (!mounted) return;
    if (error == null) {
      widget.onLeadChanged?.call();
      _snack(l10n.statusUpdated);
    } else {
      _snack(appErrorMessage(l10n, error));
    }
  }

  Future<void> _pickFollowUp() async {
    final current = _controller.followUp;
    final now = _controller.now;
    final today = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    _controller.setFollowUp(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _saveCall() async {
    FocusScope.of(context).unfocus();
    final result = await _controller.saveCall(_noteController.text);
    if (!mounted) return;
    switch (result.status) {
      case SaveCallStatus.saved:
        _noteController.clear();
        widget.onLeadChanged?.call();
        _snack(_l10n.saved);
      case SaveCallStatus.failed:
        _snack(appErrorMessage(_l10n, result.error ?? AppError.unknown));
      case SaveCallStatus.invalid:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final lead = _controller.lead ?? widget.lead;
        return Scaffold(
          appBar: AppBar(title: Text(lead.displayName ?? l10n.unnamedLead)),
          body: LayoutBuilder(
            builder: (context, constraints) => _buildBody(
              l10n,
              lead,
              centeredContentPadding(constraints.maxWidth, vertical: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n, CrmLead lead, EdgeInsets padding) {
    final c = _controller;

    if (!c.hasLoaded && c.isLoading) {
      return LeadDetailSkeleton(padding: padding);
    }

    if (!c.hasLoaded) {
      final error = c.error ?? AppError.unknown;
      final unauthorized = error == AppError.unauthorized;
      return Center(
        child: SingleChildScrollView(
          child: StateMessage(
            icon: error == AppError.network
                ? Icons.wifi_off_rounded
                : Icons.cloud_off_outlined,
            title: appErrorMessage(l10n, error),
            actionLabel: unauthorized ? l10n.loginAgain : l10n.retry,
            onAction: unauthorized ? () => signOutToLogin(context) : c.load,
          ),
        ),
      );
    }

    final mobile = lead.mobileNo;
    final tel = mobile == null ? null : telUri(mobile);
    final whatsapp = mobile == null ? null : whatsappUri(mobile);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          LeadHeaderCard(
            lead: lead,
            status: c.currentStatus,
            onCall: tel == null ? null : () => _open(tel),
            onWhatsApp: whatsapp == null ? null : () => _open(whatsapp),
          ),
          if (c.statuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            StatusSection(
              statuses: c.statuses,
              current: lead.status,
              updating: c.updatingStatus,
              onSelected: _changeStatus,
            ),
          ],
          const SizedBox(height: 16),
          UpcomingFollowUpCard(task: c.nextOpenTask, now: c.now),
          const SizedBox(height: 16),
          LogCallCard(
            outcome: c.outcome,
            showOutcomeError: c.showOutcomeError,
            createsFollowUp: c.createsFollowUp,
            followUp: c.followUp,
            noteController: _noteController,
            isSaving: c.isSaving,
            onOutcomeSelected: c.selectOutcome,
            onPickFollowUp: _pickFollowUp,
            onSave: _saveCall,
          ),
          const SizedBox(height: 16),
          NotesSection(notes: c.notes),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
