import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/skeleton.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../core/contact_links.dart';
import '../../l10n/app_localizations.dart';
import 'visit_model.dart';
import 'visit_repository.dart';
import 'visits_controller.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final VisitsController _controller = VisitsController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
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
            tooltip: 'Add Visit',
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
        label: const Text('New Visit'),
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
                    label: status,
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
                  title: 'No Site Visits Found',
                  message: 'Schedule a new site visit to see it here.',
                  actionLabel: 'Add Visit',
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
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VisitDetailScreen(visit: visit)),
    );
    if (updated == true) {
      _controller.refresh();
    }
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
    final dateStr = visit.visitDate != null
        ? DateFormat('EEE, d MMM yyyy, hh:mm a').format(visit.visitDate!)
        : 'Date not set';

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
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(visit.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  visit.status,
                  style: TextStyle(
                    color: _statusColor(visit.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
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
                    onPressed: () => openExternal(telUri(visit.mobileNo!)!),
                  ),
                if (visit.latitude != null && visit.longitude != null) ...[
                  if (visit.mobileNo != null && telUri(visit.mobileNo!) != null)
                    const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.directions, size: 18),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _visit.visitDate != null
        ? DateFormat('EEE, d MMM yyyy, hh:mm a').format(_visit.visitDate!)
        : 'Date not set';

    return Scaffold(
      appBar: AppBar(title: Text(_visit.displayTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: theme.textTheme.titleSmall),
                    DropdownButton<String>(
                      value: _visit.status,
                      items: ['Planned', 'Completed', 'Cancelled']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: _updating
                          ? null
                          : (v) => v != null ? _changeStatus(v) : null,
                    ),
                  ],
                ),
                const Divider(),
                _detailRow('Date & Time', dateStr),
                if (_visit.mobileNo != null)
                  _detailRow('Mobile No', _visit.mobileNo!),
                if (_visit.village != null)
                  _detailRow('Village', _visit.village!),
                if (_visit.district != null)
                  _detailRow('District', _visit.district!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Well Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _detailRow(
                  'Diameter (ft)',
                  _visit.diameterFt?.toString() ?? 'Not specified',
                ),
                _detailRow(
                  'Expected Depth (ft)',
                  _visit.expectedDepthFt?.toString() ?? 'Not specified',
                ),
                _detailRow(
                  'Rock Starts At (ft)',
                  _visit.rockFromFt?.toString() ?? 'Not specified',
                ),
                _detailRow('Soil Type', _visit.soilType ?? 'Not specified'),
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
                    'Location GPS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Lat: ${_visit.latitude}, Lon: ${_visit.longitude}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${_visit.latitude},${_visit.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Google Maps'),
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
                    'Notes',
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CreateVisitScreen extends StatefulWidget {
  const CreateVisitScreen({super.key});

  @override
  State<CreateVisitScreen> createState() => _CreateVisitScreenState();
}

class _CreateVisitScreenState extends State<CreateVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = VisitRepository();

  final _leadNameController = TextEditingController();
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final visit = SiteVisit(
        name: '',
        leadName: _leadNameController.text.trim(),
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
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create site visit')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Site Visit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _leadNameController,
              decoration: const InputDecoration(
                labelText: 'Client / Lead Name *',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number *'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _villageController,
                    decoration: const InputDecoration(labelText: 'Village'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'District'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visit Date & Time'),
              subtitle: Text(
                DateFormat('EEE, d MMM yyyy, hh:mm a').format(_visitDate),
              ),
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
            const Text(
              'Well Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _diameterController,
                    decoration: const InputDecoration(
                      labelText: 'Diameter (ft)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _expectedDepthController,
                    decoration: const InputDecoration(labelText: 'Depth (ft)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _soilType,
              decoration: const InputDecoration(labelText: 'Soil Type'),
              items: [
                'Red Soil',
                'Black Soil',
                'Sandy Soil',
                'Rock',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) =>
                  v != null ? setState(() => _soilType = v) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Site Visit'),
            ),
          ],
        ),
      ),
    );
  }
}
