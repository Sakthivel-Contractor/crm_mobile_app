import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/app_error.dart';
import 'package:hitech_crm_app/core/relative_time.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/leads/lead_detail_screen.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';
import 'package:hitech_crm_app/features/leads/leads_controller.dart';
import 'package:hitech_crm_app/features/leads/leads_screen.dart';
import 'package:hitech_crm_app/features/leads/new_lead_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

CrmLead _lead(int i, {String? status = 'New'}) => CrmLead(
  name: 'CRM-LEAD-$i',
  leadName: 'Lead $i',
  mobileNo: '98400${i.toString().padLeft(5, '0')}',
  source: 'Walk-in',
  status: status,
  modified: DateTime.now().subtract(const Duration(hours: 2)),
);

/// In-memory repository: [total] leads, paged like Frappe.
class FakeLeadRepository extends LeadRepository {
  FakeLeadRepository({this.total = 45, this.failWith});

  int total;
  AppError? failWith;
  AppError? createError;
  ({
    String firstName,
    String status,
    String? mobileNo,
    String? district,
    String? whenStart,
  })?
  created;
  final calls = <({String? search, String? status, int start})>[];
  Completer<void>? gate;

  @override
  Future<List<CrmLead>> fetchLeads({
    String? search,
    String? status,
    String? source,
    String? district,
    int start = 0,
    int pageLength = LeadRepository.defaultPageLength,
  }) async {
    calls.add((search: search, status: status, start: start));
    await gate?.future;
    if (failWith != null) throw AppException(failWith!);
    final end = (start + pageLength).clamp(0, total);
    return [for (var i = start; i < end; i++) _lead(i)];
  }

  @override
  Future<List<LeadStatus>> fetchStatuses() async => const [
    LeadStatus(name: 'New', color: 'gray', position: 1, type: 'Open'),
    LeadStatus(name: 'Qualified', color: 'green', position: 2, type: 'Won'),
  ];

  @override
  Future<CrmLead> createLead({
    required String firstName,
    required String status,
    String? lastName,
    String? mobileNo,
    String? email,
    String? village,
    String? district,
    String? workType,
    String? whenStart,
  }) async {
    if (createError != null) throw AppException(createError!);
    created = (
      firstName: firstName,
      status: status,
      mobileNo: mobileNo,
      district: district,
      whenStart: whenStart,
    );
    return CrmLead(
      name: 'CRM-LEAD-NEW',
      firstName: firstName,
      lastName: lastName,
      mobileNo: mobileNo,
      status: status,
    );
  }
}

Widget _app(Widget home, {Locale locale = const Locale('ta')}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: const [Locale('ta'), Locale('en')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  group('CrmLead.fromJson', () {
    test('parses a full row', () {
      final lead = CrmLead.fromJson({
        'name': 'CRM-LEAD-1',
        'first_name': 'Ravi',
        'last_name': 'Kumar',
        'lead_name': 'Ravi Kumar',
        'mobile_no': '9840000000',
        'status': 'New',
        'custom_when_start': 'Next month',
        'modified': '2026-10-19 10:15:30.123456',
      });
      expect(lead.displayName, 'Ravi Kumar');
      expect(lead.whenStart, 'Next month');
      expect(lead.modified, DateTime(2026, 10, 19, 10, 15, 30, 123, 456));
    });

    test('missing, null and wrongly typed fields do not crash', () {
      final lead = CrmLead.fromJson({
        'mobile_no': null,
        'status': 42,
        'modified': 12345,
        'first_name': '  ',
        'last_name': 'Kumar',
      });
      expect(lead.name, '');
      expect(lead.mobileNo, isNull);
      expect(lead.status, '42');
      expect(lead.modified, isNull);
      expect(lead.displayName, 'Kumar');
      expect(CrmLead.fromJson(const {}).displayName, isNull);
    });
  });

  group('LeadsController', () {
    test('lead list does not require the optional when-start field', () {
      final fields = jsonDecode(
        LeadRepository.buildLeadListQuery()['fields'] as String,
      ) as List<dynamic>;
      expect(fields, isNot(contains('custom_when_start')));
    });

    test('pages by 20 and stops when a page is short', () async {
      final repo = FakeLeadRepository(total: 45);
      final c = LeadsController(repository: repo);
      await c.init();
      expect(c.items.length, 20);
      expect(c.hasMore, isTrue);

      await c.loadMore();
      await c.loadMore();
      expect(c.items.length, 45);
      expect(c.hasMore, isFalse);
      expect(c.page, 3);

      await c.loadMore(); // no request once exhausted
      expect(repo.calls.map((r) => r.start), [0, 20, 40]);
    });

    test('debounces search and filters by status', () async {
      final repo = FakeLeadRepository();
      final c = LeadsController(repository: repo);
      await c.init();

      c.setSearch('r');
      c.setSearch('ra');
      c.setSearch('ravi');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.calls.where((r) => r.search == 'ravi').length, 1);
      expect(repo.calls.where((r) => r.search == 'ra'), isEmpty);

      c.setStatus('Qualified');
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls.last.status, 'Qualified');
      expect(repo.calls.last.search, 'ravi');
    });

    test('maps failures to an AppError', () async {
      final c = LeadsController(
        repository: FakeLeadRepository(failWith: AppError.network),
      );
      await c.init();
      expect(c.error, AppError.network);
      expect(c.items, isEmpty);
      expect(c.isLoading, isFalse);
    });
  });

  testWidgets('relative time in Tamil and English', (tester) async {
    final now = DateTime(2026, 10, 19, 12);
    late String ta, en;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            ta = formatRelativeTime(
              context,
              now.subtract(const Duration(hours: 2)),
              now: now,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            en = formatRelativeTime(
              context,
              now.subtract(const Duration(hours: 2)),
              now: now,
            );
            return const SizedBox();
          },
        ),
        locale: const Locale('en'),
      ),
    );
    expect(ta, '2 மணி நேரம் முன்');
    expect(en, '2h ago');
  });

  group('LeadsScreen', () {
    Future<void> setPhone(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('skeleton, then cards with status chips', (tester) async {
      await setPhone(tester);
      final repo = FakeLeadRepository()..gate = Completer<void>();
      final controller = LeadsController(repository: repo);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(LeadsScreen(controller: controller)));
      await tester.pump();
      expect(find.text('Lead 0'), findsNothing); // skeleton showing

      repo.gate!.complete();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Lead 0'), findsOneWidget);
      expect(find.text('அனைத்தும்'), findsOneWidget);
      expect(find.text('தகுதியானது'), findsOneWidget); // Qualified chip
      expect(find.text('2 மணி நேரம் முன்'), findsWidgets);
    });

    testWidgets('empty state', (tester) async {
      await setPhone(tester);
      final controller = LeadsController(
        repository: FakeLeadRepository(total: 0),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(LeadsScreen(controller: controller)));
      await tester.pump();
      await tester.pump();

      expect(find.text('லீட் எதுவும் இல்லை'), findsOneWidget);
    });

    testWidgets('error state retries', (tester) async {
      await setPhone(tester);
      final repo = FakeLeadRepository(failWith: AppError.server);
      final controller = LeadsController(repository: repo);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(LeadsScreen(controller: controller), locale: const Locale('en')),
      );
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Server error. Please try again later.'),
        findsOneWidget,
      );

      repo.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Lead 0'), findsOneWidget);
    });

    testWidgets('FAB creates a lead and opens its detail', (tester) async {
      await setPhone(tester);
      final repo = FakeLeadRepository();
      final controller = LeadsController(repository: repo);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          LeadsScreen(controller: controller, newLeadRepository: repo),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('New lead'), findsOneWidget);
      expect(find.text('Qualified'), findsNothing);

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
      expect(repo.created, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'Ravi');
      await tester.enterText(find.byType(TextFormField).at(2), '9840012345');
      await tester.ensureVisible(find.text('When start'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'When start'),
        'Next month',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.created?.firstName, 'Ravi');
      expect(repo.created?.status, 'New');
      expect(repo.created?.mobileNo, '9840012345');
      expect(repo.created?.whenStart, 'Next month');
      expect(find.byType(LeadDetailScreen), findsOneWidget);
    });

    testWidgets('new lead rejects invalid optional contact details', (
      tester,
    ) async {
      await setPhone(tester);
      final repo = FakeLeadRepository();
      await tester.pumpWidget(
        _app(NewLeadScreen(repository: repo), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Ravi');
      await tester.enterText(find.byType(TextFormField).at(2), 'abc');
      await tester.enterText(find.byType(TextFormField).at(3), 'not-an-email');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repo.created, isNull);
    });

    testWidgets('failed save keeps form and allows retry', (tester) async {
      await setPhone(tester);
      final repo = FakeLeadRepository()..createError = AppError.network;
      await tester.pumpWidget(
        _app(
          // Exercise the form without depending on the list's network state.
          NewLeadScreen(repository: repo),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Ravi');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Check your internet connection'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);

      repo.createError = null;
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.created?.firstName, 'Ravi');
    });
  });
}
