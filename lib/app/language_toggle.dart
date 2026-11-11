import 'package:flutter/material.dart';

import '../core/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// "தமிழ் | EN" pill switch. Changing it rebuilds the whole app in the new
/// language.
///
/// Built from a plain Row instead of SegmentedButton: SegmentedButton sizes
/// segments from intrinsic text widths, which on web come out narrower than
/// the painted Tamil text and clip "தமிழ்".
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.onDarkBackground = false});

  /// Use light colours, e.g. on the primary-coloured header.
  final bool onDarkBackground;

  static const double _pillHeight = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = LocaleController.instance;
    final outline = onDarkBackground ? Colors.white : AppTheme.primary;

    Widget segment(Locale locale, String label) => _Segment(
      label: label,
      selected: controller.locale == locale,
      onDarkBackground: onDarkBackground,
      onTap: () => controller.setLocale(locale),
    );

    // 48px tall for touch; the visible pill is 32px.
    return SizedBox(
      height: 48,
      child: Center(
        widthFactor: 1,
        child: Container(
          height: _pillHeight,
          decoration: ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: outline, width: 1.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              segment(LocaleController.tamil, l10n.languageTamil),
              Container(width: 1.2, color: outline),
              segment(LocaleController.english, l10n.languageEnglish),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onDarkBackground,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool onDarkBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (onDarkBackground) {
      background = selected ? Colors.white : Colors.transparent;
      foreground = selected ? AppTheme.primary : Colors.white;
    } else {
      background = selected ? AppTheme.primary : Colors.white;
      foreground = selected ? Colors.white : AppTheme.primary;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
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
