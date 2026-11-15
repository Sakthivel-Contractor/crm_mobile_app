import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/skeleton.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../core/contact_links.dart';
import '../../l10n/app_localizations.dart';
import '../leads/lead_model.dart';
import '../leads/lead_repository.dart';
import 'visit_model.dart';
import 'visit_repository.dart';
import 'visits_controller.dart';

String visitStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'Planned' => l10n.visitPlanned,
      'Completed' => l10n.visitCompleted,
      'Cancelled' => l10n.visitCancelled,
      _ => status,
    };

String visitSoilLabel(AppLocalizations l10n, String soil) => switch (soil) {
  'Red Soil' => l10n.visitSoilRed,
  'Black Soil' => l10n.visitSoilBlack,
  'Sandy Soil' => l10n.visitSoilSandy,
  'Rock' => l10n.visitSoilRock,
  _ => soil,
};

String visitDateLabel(BuildContext context, DateTime? date) {
  if (date == null) return AppLocalizations.of(context)!.visitDateUnset;
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat.yMMMEd(locale).add_jm().format(date);
}

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key, this.controller});

  /// Injectable for tests; created internally otherwise.
  final VisitsController? controller;

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  late final VisitsController _controller =
      widget.controller ?? VisitsController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _openCreateVisit() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateVisitScreen()));
    if (created == true) {
      _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabVisits),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.visitAdd,
            onPressed: _openCreateVisit,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _buildBody(
            l10n,
            centeredContentPadding(constraints.maxWidth, vertical: 12),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateVisit,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.visitNew),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, EdgeInsets padding) {
    if (_controller.isLoading && _controller.visits.isEmpty) {
      return ListView(
        padding: padding,
        children: const [
          SkeletonBox(height: 36, width: double.infinity, radius: 18),
          SizedBox(height: 16),
          SkeletonBox(height: 100, width: double.infinity, radius: 12),
          SizedBox(height: 12),
          SkeletonBox(height: 100, width: double.infinity, radius: 12),
        ],
      );
    }

    if (_controller.error != null && _controller.visits.isEmpty) {
      return Center(
        child: StateMessage(
          icon: _controller.error == AppError.network
              ? Icons.wifi_off_rounded
              : Icons.cloud_off_outlined,
          title: appErrorMessage(l10n, _controller.error!),
          actionLabel: l10n.retry,
          onAction: _controller.load,
        ),
      );
    }

    final filters = ['All', 'Planned', 'Completed', 'Cancelled'];

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in filters) ...[
                  AppChip(
                    label: status == 'All'
                        ? l10n.filterAll
                        : visitStatusLabel(l10n, status),
                    selected: _controller.statusFilter == status,
                    onTap: () => _controller.setFilter(status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_controller.visits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: StateMessage(
                  icon: Icons.place_outlined,
                  title: l10n.visitEmptyTitle,
                  message: l10n.visitEmptyHint,
                  actionLabel: l10n.visitAdd,
                  onAction: _openCreateVisit,
                ),
              ),
            )
          else
            for (final visit in _controller.visits) ...[
              _VisitCard(visit: visit, onTap: () => _openDetail(visit)),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 60), // Room for FAB
        ],
      ),
    );
  }

  void _openDetail(SiteVisit visit) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => VisitDetailScreen(visit: visit)),
    );
    if (mounted) _controller.refresh();
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final SiteVisit visit;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Planned':
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = visitDateLabel(context, visit.visitDate);

    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.displayTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(visit.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  visitStatusLabel(l10n, visit.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _statusColor(visit.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateStr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (visit.locationText != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    visit.locationText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if ((visit.mobileNo != null && telUri(visit.mobileNo!) != null) ||
              (visit.latitude != null && visit.longitude != null)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (visit.mobileNo != null && telUri(visit.mobileNo!) != null)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.call, size: 18),
                    tooltip: l10n.callAction,
                    onPressed: () => openExternal(telUri(visit.mobileNo!)!),
                  ),
                if (visit.latitude != null && visit.longitude != null) ...[
                  if (visit.mobileNo != null && telUri(visit.mobileNo!) != null)
                    const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.directions, size: 18),
                    tooltip: l10n.visitOpenMaps,
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${visit.latitude},${visit.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({super.key, required this.visit});

  final SiteVisit visit;

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final VisitRepository _repo = VisitRepository();
  late SiteVisit _visit = widget.visit;
  bool _updating = false;

  void _changeStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await _repo.updateStatus(_visit.name, newStatus);
      final refreshed = await _repo.getVisit(_visit.name);
      if (mounted) {
        setState(() {
          _visit = refreshed;
          _updating = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.visitStatusUpdated(visitStatusLabel(l10n, newStatus)),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.visitStatusFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = visitDateLabel(context, _visit.visitDate);

    return Scaffold(
      appBar: AppBar(title: Text(_visit.displayTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_visit.status),
                  initialValue: _visit.status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.leadStatusSection,
                  ),
                  items: ['Planned', 'Completed', 'Cancelled']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            visitStatusLabel(l10n, s),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _updating
                      ? null
                      : (v) => v != null ? _changeStatus(v) : null,
                ),
                const Divider(),
                _detailRow(l10n.visitDateTime, dateStr),
                if (_visit.mobileNo != null)
                  _detailRow(l10n.mobileNumber, _visit.mobileNo!),
                if (_visit.village != null)
                  _detailRow(l10n.village, _visit.village!),
                if (_visit.district != null)
                  _detailRow(l10n.district, _visit.district!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.visitWellDetails,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow(
                  l10n.visitDiameterFt,
                  _visit.diameterFt?.toString() ?? l10n.visitNotSpecified,
                ),
                _detailRow(
                  l10n.visitExpectedDepthFt,
                  _visit.expectedDepthFt?.toString() ?? l10n.visitNotSpecified,
                ),
                _detailRow(
                  l10n.visitRockFromFt,
                  _visit.rockFromFt?.toString() ?? l10n.visitNotSpecified,
                ),
                _detailRow(
                  l10n.visitSoilType,
                  _visit.soilType == null
                      ? l10n.visitNotSpecified
                      : visitSoilLabel(l10n, _visit.soilType!),
                ),
              ],
            ),
          ),
          if (_visit.latitude != null && _visit.longitude != null) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.visitLocationGps,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.visitCoordinates(
                      _visit.latitude.toString(),
                      _visit.longitude.toString(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${_visit.latitude},${_visit.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.visitOpenMaps),
                  ),
                ],
              ),
            ),
          ],
          if (_visit.notes != null && _visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.visitNotes,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_visit.notes!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateVisitScreen extends StatefulWidget {
  const CreateVisitScreen({
    super.key,
    this.leadRepository,
    this.visitRepository,
  });

  /// Injectable for tests.
  final LeadRepository? leadRepository;
  final VisitRepository? visitRepository;

  @override
  State<CreateVisitScreen> createState() => _CreateVisitScreenState();
}

class _CreateVisitScreenState extends State<CreateVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final VisitRepository _repo =
      widget.visitRepository ?? VisitRepository();
  late final LeadRepository _leadRepo =
      widget.leadRepository ?? LeadRepository();

  CrmLead? _selectedLead;
  AppError? _leadSearchError;
  final _mobileController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _diameterController = TextEditingController();
  final _expectedDepthController = TextEditingController();
  final _rockFromController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _visitDate = DateTime.now().add(const Duration(hours: 1));
  String _soilType = 'Red Soil';
  bool _saving = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _diameterController.dispose();
    _expectedDepthController.dispose();
    _rockFromController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final selectedLead = _selectedLead;
    if (selectedLead == null) return;
    setState(() => _saving = true);

    try {
      final visit = SiteVisit(
        name: '',
        lead: selectedLead.name,
        leadName: selectedLead.displayName ?? selectedLead.name,
        mobileNo: _mobileController.text.trim(),
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        visitDate: _visitDate,
        diameterFt: int.tryParse(_diameterController.text.trim()),
        expectedDepthFt: int.tryParse(_expectedDepthController.text.trim()),
        rockFromFt: int.tryParse(_rockFromController.text.trim()),
        soilType: _soilType,
        notes: _notesController.text.trim(),
      );

      await _repo.createVisit(visit);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appErrorMessage(AppLocalizations.of(context)!, e.error),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.visitCreateFailed),
          ),
        );
      }
    }
  }

  Future<Iterable<CrmLead>> _searchLeads(TextEditingValue value) async {
    final term = value.text.trim();
    if (term.isEmpty) return const [];
    try {
      final results = await _leadRepo.fetchLeads(search: term);
      if (mounted && _leadSearchError != null) {
        setState(() => _leadSearchError = null);
      }
      return results;
    } on AppException catch (e) {
      if (mounted) setState(() => _leadSearchError = e.error);
      return const [];
    } catch (_) {
      if (mounted) setState(() => _leadSearchError = AppError.unknown);
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Autocomplete<CrmLead>(
              displayStringForOption: (lead) => lead.displayName ?? lead.name,
              optionsBuilder: _searchLeads,
              onSelected: (lead) {
                setState(() {
                  _selectedLead = lead;
                  _leadSearchError = null;
                  _mobileController.text = lead.mobileNo ?? '';
                  _districtController.text = lead.district ?? '';
                });
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: l10n.visitSelectLead,
                        hintText: l10n.searchLeadsHint,
                      ),
                      onChanged: (text) {
                        final selected = _selectedLead;
                        if (selected != null &&
                            text != (selected.displayName ?? selected.name)) {
                          setState(() => _selectedLead = null);
                        }
                      },
                      validator: (_) =>
                          _selectedLead == null ? l10n.visitLeadRequired : null,
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final lead = options.elementAt(index);
                        return ListTile(
                          title: Text(lead.displayName ?? lead.name),
                          subtitle: lead.mobileNo == null
                              ? null
                              : Text(lead.mobileNo!),
                          onTap: () => onSelected(lead),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_leadSearchError != null) ...[
              const SizedBox(height: 6),
              Text(
                appErrorMessage(l10n, _leadSearchError!),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.error),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              decoration: InputDecoration(labelText: l10n.visitMobileRequired),
              keyboardType: TextInputType.phone,
              validator: (v) {
                final phone = v?.trim() ?? '';
                if (phone.isEmpty) return l10n.fieldRequired;
                return isDialablePhone(phone) ? null : l10n.invalidPhone;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _villageController,
                    decoration: InputDecoration(labelText: l10n.village),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    decoration: InputDecoration(labelText: l10n.district),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.visitDateTime),
              subtitle: Text(visitDateLabel(context, _visitDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _visitDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null && context.mounted) {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_visitDate),
                  );
                  if (t != null && mounted) {
                    setState(() {
                      _visitDate = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t.hour,
                        t.minute,
                      );
                    });
                  }
                }
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.visitWellDetails,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _diameterController,
                    decoration: InputDecoration(
                      labelText: l10n.visitDiameterFt,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _expectedDepthController,
                    decoration: InputDecoration(labelText: l10n.visitDepthFt),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _soilType,
              decoration: InputDecoration(labelText: l10n.visitSoilType),
              items: ['Red Soil', 'Black Soil', 'Sandy Soil', 'Rock']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(visitSoilLabel(l10n, s)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  v != null ? setState(() => _soilType = v) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.visitNotes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.visitSave),
            ),
          ],
        ),
      ),
    );
  }
}
