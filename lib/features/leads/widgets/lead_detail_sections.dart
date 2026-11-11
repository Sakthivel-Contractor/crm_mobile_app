import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/skeleton.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/relative_time.dart';
import '../../../l10n/app_localizations.dart';
import '../lead_activity_model.dart';
import '../lead_model.dart';
import '../lead_status_style.dart';

const Color _errorText = Color(0xFFB42318);
const Color _whatsappGreen = Color(0xFF075E54); // 8:1 on white

String callOutcomeLabel(AppLocalizations l10n, CallOutcome outcome) =>
    switch (outcome) {
      CallOutcome.talked => l10n.outcomeTalked,
      CallOutcome.noAnswer => l10n.outcomeNoAnswer,
      CallOutcome.busy => l10n.outcomeBusy,
      CallOutcome.wrongNumber => l10n.outcomeWrongNumber,
    };

/// "Call: Talked" → "அழைப்பு: பேசியாச்சு"; other titles unchanged.
String displayNoteTitle(AppLocalizations l10n, String? title) {
  final outcome = CallOutcome.fromNoteTitle(title);
  if (outcome != null) {
    return l10n.callNoteTitle(callOutcomeLabel(l10n, outcome));
  }
  return title ?? '';
}

String displayTaskTitle(AppLocalizations l10n, CrmTask task) =>
    task.isFollowUp ? l10n.followUpTaskTitle : (task.title ?? '');

/// "செவ், 20 அக்., 2026 முற்பகல் 10:00" / "Tue, Oct 20, 2026 10:00 AM".
String formatDateTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMEd(locale).add_jm().format(value);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textStrong),
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class LeadHeaderCard extends StatelessWidget {
  const LeadHeaderCard({
    super.key,
    required this.lead,
    required this.status,
    required this.onCall,
    required this.onWhatsApp,
  });

  final CrmLead lead;
  final LeadStatus? status;

  /// null when the lead has no mobile number.
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final name = lead.displayName ?? l10n.unnamedLead;
    final initial = lead.displayName?.characters.first.toUpperCase();
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primary,
                  child: initial == null
                      ? const Icon(Icons.person_outline)
                      : Text(
                          initial,
                          style: text.titleLarge?.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                    if (lead.mobileNo != null) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        lead.mobileNo!,
                        style: text.bodyLarge?.copyWith(
                          color: AppTheme.textStrong,
                        ),
                      ),
                    ],
                    if (lead.source != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lead.source!,
                        style: text.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                    if (lead.district != null && lead.district!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lead.district!,
                            style: text.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (lead.workType != null && lead.workType!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          localizedWorkType(l10n, lead.workType!),
                          style: text.labelMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (lead.status != null) ...[
                      const SizedBox(height: 8),
                      StatusPill(
                        label: localizedStatus(l10n, lead.status!),
                        style: StatusStyle.of(status),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(l10n.callAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                    shape: buttonShape,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(l10n.whatsappAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _whatsappGreen,
                    side: const BorderSide(color: _whatsappGreen),
                    minimumSize: const Size.fromHeight(AppTheme.controlHeight),
                    shape: buttonShape,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ status

class StatusSection extends StatelessWidget {
  const StatusSection({
    super.key,
    required this.statuses,
    required this.current,
    required this.updating,
    required this.onSelected,
  });

  final List<LeadStatus> statuses;
  final String? current;

  /// Status being saved; chips are disabled meanwhile.
  final String? updating;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _SectionTitle(l10n.leadStatusSection)),
                if (updating != null)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final status in statuses) ...[
                  _StatusChip(
                    label: localizedStatus(l10n, status.name),
                    style: StatusStyle.of(status),
                    selected: (updating ?? current) == status.name,
                    onTap: updating == null
                        ? () => onSelected(status.name)
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final StatusStyle style;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppChip(
    label: label,
    selected: selected,
    onTap: onTap,
    dot: style.foreground,
    selectedBackground: style.background,
    selectedForeground: style.foreground,
    selectedBorder: style.foreground,
  );
}

// ---------------------------------------------------------------- upcoming

class UpcomingFollowUpCard extends StatelessWidget {
  const UpcomingFollowUpCard({
    super.key,
    required this.task,
    required this.now,
  });

  final CrmTask? task;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final task = this.task;
    final overdue = task != null && task.isOverdue(now);
    final color = overdue ? _errorText : AppTheme.primary;

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (overdue ? const Color(0xFFFDECEA) : AppTheme.background),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Icon(
              overdue ? Icons.alarm : Icons.event_outlined,
              color: task == null ? AppTheme.textMuted : color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.upcomingFollowUp,
                  style: text.labelMedium?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (task == null)
                  Text(
                    l10n.noUpcomingFollowUp,
                    style: text.bodyLarge?.copyWith(color: AppTheme.textStrong),
                  )
                else ...[
                  Text(
                    task.dueDate == null
                        ? l10n.noDueDate
                        : formatDateTime(context, task.dueDate!),
                    style: text.bodyLarge?.copyWith(
                      color: overdue ? _errorText : AppTheme.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    displayTaskTitle(l10n, task),
                    style: text.bodySmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (overdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.overdue,
                style: text.labelSmall?.copyWith(
                  color: _errorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- log call

class LogCallCard extends StatelessWidget {
  const LogCallCard({
    super.key,
    required this.outcome,
    required this.showOutcomeError,
    required this.createsFollowUp,
    required this.followUp,
    required this.noteController,
    required this.isSaving,
    required this.onOutcomeSelected,
    required this.onPickFollowUp,
    required this.onSave,
  });

  final CallOutcome? outcome;
  final bool showOutcomeError;
  final bool createsFollowUp;
  final DateTime followUp;
  final TextEditingController noteController;
  final bool isSaving;
  final ValueChanged<CallOutcome> onOutcomeSelected;
  final VoidCallback onPickFollowUp;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final labelStyle = text.bodyMedium?.copyWith(
      color: AppTheme.textMuted,
      fontWeight: FontWeight.w600,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      borderSide: BorderSide.none,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(l10n.logCallTitle),
          const SizedBox(height: 16),
          Text(l10n.callOutcome, style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final value in CallOutcome.values)
                AppChip(
                  label: callOutcomeLabel(l10n, value),
                  selected: outcome == value,
                  onTap: isSaving ? null : () => onOutcomeSelected(value),
                  borderColor: showOutcomeError ? _errorText : AppTheme.border,
                ),
            ],
          ),
          if (showOutcomeError) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.outcomeRequired,
                style: text.bodySmall?.copyWith(color: _errorText),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.callNoteLabel, style: labelStyle),
          const SizedBox(height: 8),
          Semantics(
            label: l10n.callNoteLabel,
            child: TextField(
              controller: noteController,
              enabled: !isSaving,
              inputFormatters: [LengthLimitingTextInputFormatter(2000)],
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.callNoteHint,
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.background,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                disabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.nextFollowUp, style: labelStyle),
          const SizedBox(height: 8),
          if (createsFollowUp)
            Semantics(
              button: true,
              label:
                  '${l10n.changeFollowUp}: ${formatDateTime(context, followUp)}',
              excludeSemantics: true,
              child: Material(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: InkWell(
                  onTap: isSaving ? null : onPickFollowUp,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppTheme.inputHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formatDateTime(context, followUp),
                              style: text.bodyLarge?.copyWith(
                                color: AppTheme.textStrong,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar_outlined,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              l10n.noFollowUpForWrongNumber,
              style: text.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.secondary,
              disabledForegroundColor: Colors.white,
              minimumSize: const Size.fromHeight(AppTheme.primaryButtonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: isSaving
                ? Semantics(
                    label: l10n.save,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- history

class NotesSection extends StatelessWidget {
  const NotesSection({super.key, required this.notes});

  final List<CrmNote> notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: AppTheme.textMuted);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionTitle(l10n.historyTitle),
          ),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(l10n.noNotes, style: muted),
            ),
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 16, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayNoteTitle(l10n, notes[i].title),
                          style: text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textStrong,
                          ),
                        ),
                      ),
                      if (notes[i].creation != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatRelativeTime(context, notes[i].creation!),
                          style: muted,
                        ),
                      ],
                    ],
                  ),
                  if (notes[i].content != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notes[i].content!,
                      style: text.bodyMedium?.copyWith(
                        color: AppTheme.textStrong,
                      ),
                    ),
                  ],
                  if (notes[i].owner != null) ...[
                    const SizedBox(height: 4),
                    Text(notes[i].owner!, style: muted),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- skeleton

class LeadDetailSkeleton extends StatelessWidget {
  const LeadDetailSkeleton({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => SurfaceCard(
      child: SizedBox(
        height: height,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 14),
            SizedBox(height: 16),
            SkeletonBox(height: 12),
            SizedBox(height: 8),
            SkeletonBox(width: 200, height: 12),
          ],
        ),
      ),
    );

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SurfaceCard(
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 56, circle: true),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 180, height: 18),
                          SizedBox(height: 8),
                          SkeletonBox(width: 120, height: 14),
                          SizedBox(height: 8),
                          SkeletonBox(width: 64, height: 20, radius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 48, radius: 12)),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonBox(height: 48, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          block(72),
          const SizedBox(height: 16),
          block(180),
        ],
      ),
    );
  }
}
