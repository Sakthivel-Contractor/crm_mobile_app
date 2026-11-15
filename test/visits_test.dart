import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';
import 'package:hitech_crm_app/features/visits/visit_model.dart';
import 'package:hitech_crm_app/features/visits/visit_repository.dart';
import 'package:hitech_crm_app/features/visits/visits_controller.dart';
import 'package:hitech_crm_app/features/visits/visits_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

class _FakeVisitRepository extends VisitRepository {
  SiteVisit? created;

  @override
  Future<SiteVisit> createVisit(SiteVisit visit) async {
    created = visit;
    return SiteVisit(name: 'VISIT-NEW', lead: visit.lead);
  }

  @override
  Future<List<SiteVisit>> fetchVisits({
    String? status,
    String? search,
    int limit = 50,
  }) async => [
    SiteVisit(
      name: 'VISIT-1',
      leadName: 'ரவி',
      status: 'Planned',
      visitDate: DateTime(2026, 11, 15, 10, 30),
      mobileNo: '9840012345',
      district: 'மதுரை',
      diameterFt: 20,
      soilType: 'Red Soil',
    ),
  ];
}

class _FakeLeadRepository extends LeadRepository {
  @override
  Future<List<CrmLead>> fetchLeads({
    String? search,
    String? status,
    String? source,
    String? district,
    int start = 0,
    int pageLength = LeadRepository.defaultPageLength,
  }) async => [
    const CrmLead(
      name: 'CRM-LEAD-1',
      leadName: 'Ravi',
      mobileNo: '9840012345',
      district: 'Madurai',
    ),
  ];
}

Future<void> _pump(WidgetTester tester, Widget child, Locale locale) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: AppTheme.clampTextScale,
      locale: locale,
      supportedLocales: const [Locale('ta'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tamil visit list and detail fit a phone', (tester) async {
    final controller = VisitsController(repository: _FakeVisitRepository());
    addTearDown(controller.dispose);
    await _pump(
      tester,
      VisitsScreen(controller: controller),
      const Locale('ta'),
    );
    expect(find.text('திட்டமிடப்பட்டது'), findsWidgets);
    expect(find.text('புதிய இட ஆய்வு'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ரவி'));
    await tester.pumpAndSettle();
    expect(find.text('கிணறு விவரங்கள்'), findsOneWidget);
    expect(find.text('செம்மண்'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamil create form validates required fields', (tester) async {
    final visits = _FakeVisitRepository();
    await _pump(
      tester,
      CreateVisitScreen(
        leadRepository: _FakeLeadRepository(),
        visitRepository: visits,
      ),
      const Locale('ta'),
    );
    expect(find.text('லீட்டைத் தேர்ந்தெடுக்கவும் *'), findsOneWidget);
    expect(find.text('ஆய்வு தேதி மற்றும் நேரம்'), findsOneWidget);
    await tester.ensureVisible(find.text('இட ஆய்வை சேமி'));
    await tester.tap(find.text('இட ஆய்வை சேமி'));
    await tester.pumpAndSettle();
    expect(
      find.text('தேடல் முடிவிலிருந்து ஒரு லீட்டைத் தேர்ந்தெடுக்கவும்'),
      findsOneWidget,
    );
    expect(find.text('இது தேவை'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, 'Ravi');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ravi').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('இட ஆய்வை சேமி'));
    await tester.tap(find.text('இட ஆய்வை சேமி'));
    await tester.pumpAndSettle();
    expect(visits.created?.lead, 'CRM-LEAD-1');
    expect(visits.created?.mobileNo, '9840012345');
    expect(visits.created?.toJson()['lead'], 'CRM-LEAD-1');
    expect(tester.takeException(), isNull);
  });
}
