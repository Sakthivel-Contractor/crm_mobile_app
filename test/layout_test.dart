import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/features/auth/login_screen.dart';
import 'package:hitech_crm_app/features/leads/lead_detail_controller.dart';
import 'package:hitech_crm_app/features/leads/lead_detail_screen.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/leads/leads_controller.dart';
import 'package:hitech_crm_app/features/leads/leads_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

import 'lead_detail_test.dart' show FakeDetailRepository;
import 'leads_test.dart' show FakeLeadRepository;

/// Pixel 7 viewport, with the system font size above the app's clamp.
Future<void> _pump(WidgetTester tester, Widget home, Locale locale) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3; // clamped to 1.15
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: AppTheme.clampTextScale,
      locale: locale,
      supportedLocales: const [Locale('ta'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'site_url': 'https://crm.hitech.in',
    });
    PackageInfo.setMockInitialValues(
      appName: 'HI Tech CRM',
      packageName: 'hitech_crm_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('text scale is clamped to 0.9–1.15', () {
    expect(AppTheme.minTextScale, 0.9);
    expect(AppTheme.maxTextScale, 1.15);
  });

  for (final locale in const [Locale('ta'), Locale('en')]) {
    final lang = locale.languageCode;

    testWidgets('login fits on Pixel 7 at large text ($lang)', (tester) async {
      await _pump(tester, const LoginScreen(), locale);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leads fit on Pixel 7 at large text ($lang)', (tester) async {
      final controller = LeadsController(repository: FakeLeadRepository());
      addTearDown(controller.dispose);
      await _pump(tester, LeadsScreen(controller: controller), locale);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lead detail fits on Pixel 7 at large text ($lang)', (
      tester,
    ) async {
      final controller = LeadDetailController(
        leadName: 'CRM-LEAD-1',
        repository: FakeDetailRepository(),
      );
      addTearDown(controller.dispose);
      await _pump(
        tester,
        LeadDetailScreen(
          lead: const CrmLead(name: 'CRM-LEAD-1'),
          controller: controller,
        ),
        locale,
      );
      expect(tester.takeException(), isNull);

      // Scroll through every section.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
