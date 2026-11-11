import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_error.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Max width of list/detail content on wide screens.
const double contentMaxWidth = 720;

/// Horizontal padding that keeps content at most [contentMaxWidth] wide and
/// centred, with a 16px gutter on phones.
EdgeInsets centeredContentPadding(
  double availableWidth, {
  double vertical = 0,
}) {
  final side = math.max(16.0, (availableWidth - contentMaxWidth) / 2);
  return EdgeInsets.symmetric(horizontal: side, vertical: vertical);
}

/// White card with a 1px border and 12px radius.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radius);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Icon + title + optional message + optional action, centred.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textStrong,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, AppTheme.controlHeight),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// 32px pill chip with an optional colour dot.
///
/// Used instead of ChoiceChip, which gives its label less width than the
/// painted text with the compact theme and clips it (worst with Tamil). The
/// tap area is padded to 48px.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
    this.selectedBackground = AppTheme.primary,
    this.selectedForeground = Colors.white,
    this.selectedBorder,
    this.borderColor = AppTheme.border,
    this.trailingIcon,
  });

  final String label;
  final bool selected;

  /// null disables the chip.
  final VoidCallback? onTap;
  final Color? dot;
  final Color selectedBackground;
  final Color selectedForeground;

  /// Defaults to [selectedBackground].
  final Color? selectedBorder;

  /// Unselected border, e.g. red to flag a validation error.
  final Color borderColor;

  /// Small icon after the label, e.g. a close icon on a removable filter.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final side = selected
        ? BorderSide(color: selectedBorder ?? selectedBackground, width: 1.5)
        : BorderSide(color: borderColor);
    final shape = StadiumBorder(side: side);

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: selected ? selectedBackground : Colors.white,
            shape: shape,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: SizedBox(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dot != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                            border: selected && selectedBackground == dot
                                ? Border.all(color: Colors.white, width: 1.5)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selected
                                  ? selectedForeground
                                  : AppTheme.textStrong,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          trailingIcon,
                          size: AppTheme.smallIconSize,
                          color: selected
                              ? selectedForeground
                              : AppTheme.textStrong,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder body for tabs that are not built yet.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: StateMessage(
        icon: icon,
        title: l10n.comingSoon,
        message: l10n.comingSoonHint,
      ),
    );
  }
}

/// Localized message for a data-layer [AppError].
String appErrorMessage(AppLocalizations l10n, AppError error) =>
    switch (error) {
      AppError.network => l10n.errorNoInternet,
      AppError.unauthorized => l10n.errorUnauthorized,
      AppError.server => l10n.errorServer,
      AppError.unknown => l10n.errorGeneric,
    };
