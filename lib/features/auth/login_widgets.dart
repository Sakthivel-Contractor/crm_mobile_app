import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Colours used only by the login screen.
class LoginColors {
  LoginColors._();

  static const Color label = Color(0xFF5B6B78); // 5.3:1 on white
  static const Color fill = AppTheme.background; // #F3F5F7
  static const Color errorBackground = Color(0xFFFDECEA);
  static const Color errorText = Color(0xFFB42318); // 6:1 on errorBackground
}

const double loginFieldHeight = AppTheme.inputHeight;

/// True when the platform asks for reduced motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Filled input with no border at rest and a 1.5px primary border on focus.
InputDecoration loginInputDecoration({
  required IconData icon,
  String? hintText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border([BorderSide side = BorderSide.none]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        borderSide: side,
      );

  const errorSide = BorderSide(color: LoginColors.errorText, width: 1.5);

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: LoginColors.label),
    prefixIcon: Icon(icon, color: LoginColors.label),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: LoginColors.fill,
    constraints: const BoxConstraints(minHeight: loginFieldHeight),
    contentPadding: AppTheme.inputPadding,
    border: border(),
    enabledBorder: border(),
    disabledBorder: border(),
    focusedBorder: border(
      const BorderSide(color: AppTheme.primary, width: 1.5),
    ),
    errorBorder: border(errorSide),
    focusedErrorBorder: border(errorSide),
    errorStyle: const TextStyle(color: LoginColors.errorText),
  );
}

/// Deep-blue panel with a subtle diagonal band.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DiagonalPainter(), child: child);
  }
}

class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.primary);

    final band = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width, size.height * 0.30)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      band,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.08),
      size.shortestSide * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalPainter oldDelegate) => false;
}

/// 64px app icon with 16px rounded corners.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  static const String asset = 'assets/icon/app_icon_1024.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        asset,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // Decorative: the app name is announced right below it.
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Logo, app name, subtitle and optional tagline, in white.
class BrandBlock extends StatelessWidget {
  const BrandBlock({
    super.key,
    required this.appName,
    required this.subtitle,
    this.tagline,
  });

  final String appName;
  final String subtitle;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: 0.8);

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(child: BrandMark()),
          const SizedBox(height: 16),
          Text(
            appName,
            style: text.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: text.bodyLarge?.copyWith(color: muted)),
          if (tagline != null) ...[
            const SizedBox(height: 24),
            Text(tagline!, style: text.titleMedium?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}

/// 13px label shown above a field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w600, color: LoginColors.label),
    );
  }
}

/// Soft red inline error with an icon. Announced by screen readers.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LoginColors.errorBackground,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: LoginColors.errorText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoginColors.errorText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width 52px primary button with a press-scale effect and a white
/// spinner while [loading]. Disabled while loading.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.loading;

    return Listener(
      onPointerDown: (_) => _setPressed(enabled),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 100),
        child: FilledButton(
          onPressed: enabled ? widget.onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            // Keep the brand colour while loading; the spinner shows state.
            disabledBackgroundColor: AppTheme.primary,
            disabledForegroundColor: Colors.white,
            minimumSize: const Size.fromHeight(AppTheme.primaryButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          child: widget.loading
              ? Semantics(
                  label: widget.label,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(widget.label),
        ),
      ),
    );
  }
}
