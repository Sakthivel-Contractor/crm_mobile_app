import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/language_toggle.dart';
import '../../app/theme.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';
import '../../l10n/app_localizations.dart';
import '../shell/app_shell.dart';
import 'login_widgets.dart';
import '../../core/log.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Width from which the two-column layout is used.
  static const double wideBreakpoint = 600;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  AuthErrorType? _error;

  /// The saved URL has been read; until then the server section is empty.
  bool _urlLoaded = false;

  /// Show the URL field instead of the collapsed "Server: host" row.
  bool _editingUrl = true;

  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_fade);
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _prefillUrl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (reduceMotion(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _urlFocus.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prefillUrl() async {
    final url = await AppStorage.loadSiteUrl();
    if (!mounted) return;
    setState(() {
      if (url != null && url.isNotEmpty && _urlController.text.isEmpty) {
        _urlController.text = url;
        _editingUrl = false;
      }
      _urlLoaded = true;
    });
  }

  static String _messageFor(AppLocalizations l10n, AuthErrorType type) =>
      switch (type) {
        AuthErrorType.serverUnreachable => l10n.errorServerUnreachable,
        AuthErrorType.invalidCredentials => l10n.errorWrongPassword,
        AuthErrorType.network => l10n.errorNoInternet,
        AuthErrorType.insecureUrl => l10n.errorInsecureUrl,
        AuthErrorType.unknown => l10n.errorUnknown,
      };

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final fullName = await ApiClient.instance.signIn(
        siteUrl: _urlController.text,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      // The password is never kept after a successful login.
      _passwordController.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => AppShell(fullName: fullName)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.type;
        _loading = false;
        // Let the user fix a wrong saved URL.
        if (e.type == AuthErrorType.serverUnreachable) _editingUrl = true;
      });
    } catch (e) {
      // Never leave the button spinning on an unexpected failure.
      logDebug('Login failed unexpectedly: $e');
      if (!mounted) return;
      setState(() {
        _error = AuthErrorType.unknown;
        _loading = false;
        _editingUrl = true;
      });
    }
  }

  void _expandUrl() {
    setState(() => _editingUrl = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _urlFocus.requestFocus();
    });
  }

  Duration _motion(int ms) =>
      reduceMotion(context) ? Duration.zero : Duration(milliseconds: ms);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide =
        MediaQuery.sizeOf(context).width >= LoginScreen.wideBreakpoint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isWide ? _buildWide(l10n) : _buildMobile(l10n),
      ),
    );
  }

  // ---------------------------------------------------------------- layouts

  Widget _buildMobile(AppLocalizations l10n) {
    final headerHeight = math.max(
      MediaQuery.sizeOf(context).height * 0.35,
      240.0,
    );
    const overlap = 24.0;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: headerHeight,
                child: BrandBackground(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        8,
                        16,
                        overlap + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: LanguageToggle(onDarkBackground: true),
                          ),
                          const Spacer(),
                          BrandBlock(
                            appName: l10n.appName,
                            subtitle: l10n.appSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -overlap),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _animated(_buildForm(l10n)),
                          const Spacer(),
                          const SizedBox(height: 32),
                          _buildFooter(l10n),
                          // The sheet is shifted up by `overlap`; keep the
                          // footer clear of the bottom edge.
                          const SizedBox(height: overlap + 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWide(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: BrandBackground(
            child: SafeArea(
              right: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 16, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: LanguageToggle(onDarkBackground: true),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: BrandBlock(
                        appName: l10n.appName,
                        subtitle: l10n.appSubtitle,
                        tagline: l10n.brandTagline,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: SafeArea(
            left: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _animated(_buildForm(l10n)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                  child: _buildFooter(l10n),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _animated(Widget child) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: child),
  );

  // ------------------------------------------------------------------- form

  Widget _buildForm(AppLocalizations l10n) {
    final text = Theme.of(context).textTheme;

    String? required(String? value) =>
        (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.loginTitle,
                style: text.titleLarge?.copyWith(color: AppTheme.textStrong),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginHint,
              style: text.bodyMedium?.copyWith(color: LoginColors.label),
            ),
            const SizedBox(height: 32),
            AnimatedSize(
              duration: _motion(200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _buildServerSection(l10n, required),
            ),
            _LabeledField(
              label: l10n.username,
              field: TextFormField(
                controller: _usernameController,
                inputFormatters: [LengthLimitingTextInputFormatter(140)],
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: loginInputDecoration(icon: Icons.person_outline),
                validator: required,
              ),
            ),
            const SizedBox(height: 24),
            _LabeledField(
              label: l10n.password,
              field: TextFormField(
                controller: _passwordController,
                inputFormatters: [LengthLimitingTextInputFormatter(256)],
                enabled: !_loading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: loginInputDecoration(
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: LoginColors.label,
                    ),
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: _motion(200),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      key: ValueKey(_error),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ErrorBanner(message: _messageFor(l10n, _error!)),
                    ),
            ),
            PrimaryButton(
              label: l10n.loginButton,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSection(
    AppLocalizations l10n,
    String? Function(String?) validator,
  ) {
    if (!_urlLoaded) return const SizedBox(width: double.infinity);

    if (!_editingUrl) {
      final saved = _urlController.text;
      final host = Uri.tryParse(saved)?.host;
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _ServerSummary(
          summary: l10n.serverSummary(
            (host == null || host.isEmpty) ? saved : host,
          ),
          action: l10n.changeServer,
          onTap: _loading ? null : _expandUrl,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _LabeledField(
        label: l10n.serverUrl,
        field: TextFormField(
          controller: _urlController,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
          focusNode: _urlFocus,
          enabled: !_loading,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: loginInputDecoration(
            icon: Icons.dns_outlined,
            hintText: l10n.serverUrlHint,
          ),
          validator: (value) {
            final missing = validator(value);
            if (missing != null) return missing;
            return ApiClient.isAllowedSiteUrl(ApiClient.normalizeUrl(value!))
                ? null
                : AppLocalizations.of(context)!.errorInsecureUrl;
          },
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final version = snapshot.data?.version;
        return Text(
          (version == null || version.isEmpty)
              ? l10n.footerCopyright
              : l10n.footerWithVersion(version),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

/// Visual label above a field; screen readers get it on the field itself.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: FieldLabel(label)),
        const SizedBox(height: 8),
        Semantics(label: label, child: field),
      ],
    );
  }
}

/// Collapsed "Server: host · Change" row, shown when a URL is saved.
class _ServerSummary extends StatelessWidget {
  const _ServerSummary({
    required this.summary,
    required this.action,
    required this.onTap,
  });

  final String summary;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$summary, $action',
      excludeSemantics: true,
      child: Material(
        color: LoginColors.fill,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.dns_outlined,
                    size: 18,
                    color: LoginColors.label,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: LoginColors.label,
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      color: LoginColors.label,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    action,
                    style: text.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
