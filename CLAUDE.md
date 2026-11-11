# HI Tech CRM (Flutter, Frappe CRM backend)

## Localization — applies to every screen, existing and new
- The app is bilingual: Tamil (default, `ta`) and English (`en`).
- Never hard-code user-facing text in widgets. Add a camelCase key to BOTH
  `lib/l10n/app_ta.arb` (template, with an `@key` description) and
  `lib/l10n/app_en.arb`, run `flutter gen-l10n`, then use
  `AppLocalizations.of(context)!.key`.
- Placeholders use ARB syntax, e.g. `"welcomeUser": "வணக்கம், {name}"`.
- The API/core layer never returns display text: it returns an error enum/code
  (e.g. `AuthErrorType`) and the widget maps it to a localized string.
  Store the enum in state, not the message, so it re-translates on switch.
- Data requests go through `ApiClient.instance.getJson` and throw
  `AppException(AppError.network|unauthorized|server|unknown)`
  (`lib/core/app_error.dart`); show them with `appErrorMessage()` from
  `lib/app/widgets.dart`.
- Language is held by `LocaleController.instance` (`lib/core/locale_controller.dart`,
  persisted under shared_preferences key `app_locale`). Reuse `LanguageToggle`
  (`lib/app/language_toggle.dart`) on new top-level screens.
- Typography lives only in `lib/app/theme.dart` (line height 1.35 for Tamil).
  Never write `fontSize:` in widgets; use `Theme.of(context).textTheme.*` and
  `copyWith` only for colour/weight. Sizes: AppTheme.controlHeight (44),
  primaryButtonHeight (48), inputHeight (46). Truncate names in lists with
  `maxLines` + ellipsis.

## Structure
- `lib/features/<feature>/`: `*_model.dart` (safe `fromJson`), `*_repository.dart`
  (API calls), `*_controller.dart` (ChangeNotifier state), `*_screen.dart` +
  `widgets/`. No business logic in `build()`; no extra state packages.
- Shared UI: `SurfaceCard`, `StateMessage`, `centeredContentPadding` (720px max
  width) in `lib/app/widgets.dart`; colours in `AppTheme`.

## Security rules (see test/security_test.dart)
- Never store or log the password; clear it after login. Never log cookies,
  tokens or request/response bodies. Log only via `logDebug()`
  (`lib/core/log.dart`, debug builds only) — `print`/`debugPrint` elsewhere
  fails the tests.
- Server URL must be https:// (`ApiClient.isAllowedSiteUrl`); http only for
  localhost/10.0.2.2 in debug builds. Android cleartext is blocked by
  `res/xml/network_security_config.xml` (debug override in `src/debug`).
- Cookies live only in the app support dir; user info only in
  flutter_secure_storage (Keystore AES-GCM). Only `ApiClient.signOut()` clears
  them. Session expiry = server-confirmed 401/403/"Guest", never network errors.
- User text goes into Frappe filters only as a value in a `jsonEncode`d list.
- External links only via `telUri`/`whatsappUri` + `openExternal`
  (`lib/core/contact_links.dart`), which allow-lists what can be opened.
- Future photo uploads: images only, compressed, `is_private: 1`.
- Optional screenshot block (FLAG_SECURE) on lead details: Profile switch,
  `lib/core/screen_security.dart` + `MainActivity.kt`, default off.
- Optional app lock (Profile switch, default off): `lib/core/app_lock.dart`
  + `lib/features/lock/`. 4-digit PIN stored only as a salted PBKDF2 hash in
  secure storage; optional fingerprint via local_auth (needs
  `FlutterFragmentActivity` + AppCompat themes). Locks on start and after
  1 min in background; wait after 5 wrong PINs, sign-out after 10. Cleared
  on sign-out/session expiry. The lock overlay sits above the navigator
  (`AppLockGate` in `MaterialApp.builder`), so it uses no dialogs/routes.
- Release build: `flutter build apk --release --obfuscate --split-debug-info=build/symbols`
  (keep `build/symbols` to read crash stack traces).

## Checks
Run `flutter gen-l10n`, `flutter analyze` and `flutter test`; keep them clean.
