import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/api_client.dart';
import 'package:hitech_crm_app/core/locale_controller.dart';
import 'package:hitech_crm_app/features/auth/login_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

Future<void> _pumpLogin(
  WidgetTester tester, {
  required Size size,
  Map<String, Object> prefs = const {},
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues(prefs);
  PackageInfo.setMockInitialValues(
    appName: 'HI Tech CRM',
    packageName: 'hitech_crm_app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = LocaleController.instance;
  await controller.load();

  await tester.pumpWidget(
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        locale: controller.locale,
        supportedLocales: LocaleController.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ApiClient.normalizeUrl', () {
    test('adds https:// when scheme is missing', () {
      expect(
        ApiClient.normalizeUrl('crm.example.com'),
        'https://crm.example.com',
      );
    });

    test('keeps existing scheme and strips trailing slashes', () {
      expect(
        ApiClient.normalizeUrl(' http://crm.example.com// '),
        'http://crm.example.com',
      );
    });
  });

  testWidgets('mobile: defaults to Tamil and switches to English', (
    tester,
  ) async {
    await _pumpLogin(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('உள்நுழைக'), findsOneWidget);
    expect(find.text('உள்நுழை'), findsOneWidget);
    expect(find.text('சர்வர் URL'), findsOneWidget);
    expect(find.textContaining('பதிப்பு 1.0.0'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Open Well Contractor'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
    await LocaleController.instance.setLocale(LocaleController.tamil);
  });

  testWidgets('wide: brand panel and collapsed server row', (tester) async {
    await _pumpLogin(
      tester,
      size: const Size(1280, 800),
      prefs: {'site_url': 'https://crm.hitech.in'},
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('கிணறு பணிகள், வாடிக்கையாளர்கள், கட்டணங்கள் — ஒரே இடத்தில்'),
      findsOneWidget,
    );
    expect(find.text('சர்வர்: crm.hitech.in'), findsOneWidget);
    expect(find.text('சர்வர் URL'), findsNothing);

    await tester.tap(find.text('மாற்று'));
    await tester.pumpAndSettle();

    expect(find.text('சர்வர் URL'), findsOneWidget);
    expect(find.text('https://crm.hitech.in'), findsOneWidget);
  });

  testWidgets('empty submit shows required errors', (tester) async {
    await _pumpLogin(tester, size: const Size(390, 844));

    await tester.tap(find.text('உள்நுழை'));
    await tester.pumpAndSettle();

    expect(find.text('இது தேவை'), findsNWidgets(3));
  });
}
