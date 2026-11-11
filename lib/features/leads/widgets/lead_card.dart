import 'package:flutter/material.dart';

import '../../../app/skeleton.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/relative_time.dart';
import '../../../l10n/app_localizations.dart';
import '../lead_model.dart';
import '../lead_status_style.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({
    super.key,
    required this.lead,
    required this.status,
    required this.onTap,
  });

  final CrmLead lead;

  /// Status metadata (colour) for [CrmLead.status], if known.
  final LeadStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final name = lead.displayName ?? l10n.unnamedLead;
    final muted = text.bodySmall;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeadAvatar(name: lead.displayName),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(color: AppTheme.textStrong),
                ),
                if (lead.mobileNo != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14, // inline with 12px meta text
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lead.mobileNo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ),
                    ],
                  ),
                ],
                if (lead.source != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    lead.source!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
                if (lead.workType != null || lead.district != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (lead.workType != null && lead.workType!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            localizedWorkType(l10n, lead.workType!),
                            style: text.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (lead.district != null && lead.district!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              lead.district!,
                              style: muted,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lead.status != null)
                  StatusPill(
                    label: localizedStatus(l10n, lead.status!),
                    style: StatusStyle.of(status),
                  ),
                if (lead.modified != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatRelativeTime(context, lead.modified!),
                    maxLines: 1,
                    style: muted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle with the first letter of the lead's name.
class LeadAvatar extends StatelessWidget {
  const LeadAvatar({super.key, required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.isEmpty)
        ? null
        : name!.characters.first.toUpperCase();

    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primary,
        child: initial == null
            ? const Icon(Icons.person_outline)
            : Text(
                initial,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// Six pulsing placeholder cards shown during the first load.
class LeadSkeletonList extends StatelessWidget {
  const LeadSkeletonList({super.key, required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const SurfaceCard(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 36, height: 36, circle: true),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 110, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 64, height: 20, radius: 10),
                  SizedBox(height: 8),
                  SkeletonBox(width: 40, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
