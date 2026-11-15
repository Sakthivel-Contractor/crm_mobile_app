import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/app_error.dart';
import '../../core/contact_links.dart';
import '../../l10n/app_localizations.dart';
import 'lead_model.dart';
import 'lead_repository.dart';

/// Creates a CRM Lead. Field names and work types follow the installed
/// CRM Lead DocType and the HI Tech custom fields.
class NewLeadScreen extends StatefulWidget {
  const NewLeadScreen({super.key, this.repository});

  /// Injectable for tests.
  final LeadRepository? repository;

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  late final LeadRepository _repository = widget.repository ?? LeadRepository();
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _village = TextEditingController();
  final _district = TextEditingController();

  static const _workTypes = [
    'New Well',
    'Well Deepening',
    'Wall Construction',
    'Desilting',
    'Water Survey',
  ];

  List<LeadStatus> _statuses = const [];
  String? _status;
  String? _workType;
  bool _loadingStatuses = true;
  bool _saving = false;
  bool _created = false;
  AppError? _statusError;
  AppError? _saveError;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _mobile.dispose();
    _email.dispose();
    _village.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    setState(() {
      _loadingStatuses = true;
      _statusError = null;
    });
    try {
      // A newly created lead should begin in an open state. Closed statuses
      // can require extra server fields (such as a lost reason).
      final statuses = (await _repository.fetchStatuses())
          .where((status) => status.type == 'Open')
          .toList();
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _status = statuses.any((s) => s.name == 'New')
            ? 'New'
            : statuses.isNotEmpty
            ? statuses.first.name
            : null;
        _statusError = statuses.isEmpty ? AppError.server : null;
        _loadingStatuses = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = e.error;
        _loadingStatuses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusError = AppError.unknown;
        _loadingStatuses = false;
      });
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? AppLocalizations.of(context)!.fieldRequired
      : null;

  String? _validateMobile(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isNotEmpty && !isDialablePhone(phone)) {
      return AppLocalizations.of(context)!.invalidPhone;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return AppLocalizations.of(context)!.invalidEmail;
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || _status == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final lead = await _repository.createLead(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        mobileNo: _mobile.text.trim(),
        email: _email.text.trim(),
        village: _village.text.trim(),
        district: _district.text.trim(),
        workType: _workType,
        status: _status!,
      );
      if (!mounted) return;
      setState(() => _created = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop(lead);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.error;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = AppError.unknown;
        _saving = false;
      });
    }
  }

  String _workTypeLabel(AppLocalizations l10n, String value) => switch (value) {
    'New Well' => l10n.workTypeNewWell,
    'Well Deepening' => l10n.workTypeDeepening,
    'Wall Construction' => l10n.workTypeWall,
    'Desilting' => l10n.workTypeDesilting,
    'Water Survey' => l10n.workTypeSurvey,
    _ => value,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_saving || _created,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.newLead)),
        body: _loadingStatuses
            ? const Center(child: CircularProgressIndicator())
            : _statusError != null
            ? Center(
                child: StateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: appErrorMessage(l10n, _statusError!),
                  actionLabel: l10n.retry,
                  onAction: _loadStatuses,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => Form(
                  key: _formKey,
                  child: ListView(
                    padding: centeredContentPadding(
                      constraints.maxWidth,
                      vertical: 16,
                    ).copyWith(bottom: 32),
                    children: [
                      Text(
                        l10n.newLeadDetails,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstName,
                        decoration: InputDecoration(labelText: l10n.firstName),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastName,
                        decoration: InputDecoration(labelText: l10n.lastName),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobile,
                        decoration: InputDecoration(
                          labelText: l10n.mobileNumber,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(maxPhoneLength),
                        ],
                        validator: _validateMobile,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: l10n.emailAddress,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _village,
                        decoration: InputDecoration(labelText: l10n.village),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _district,
                        decoration: InputDecoration(labelText: l10n.district),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(140),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _workType,
                        decoration: InputDecoration(labelText: l10n.workType),
                        items: [
                          for (final value in _workTypes)
                            DropdownMenuItem(
                              value: value,
                              child: Text(_workTypeLabel(l10n, value)),
                            ),
                        ],
                        onChanged: (value) => setState(() => _workType = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: InputDecoration(
                          labelText: l10n.leadStatusSection,
                        ),
                        items: [
                          for (final status in _statuses)
                            DropdownMenuItem(
                              value: status.name,
                              child: Text(
                                status.name == 'New'
                                    ? l10n.statusNew
                                    : status.name,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _status = value),
                        validator: _required,
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          appErrorMessage(l10n, _saveError!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppTheme.primaryButtonHeight,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.save),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
