import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/app_error.dart';
import 'package:hitech_crm_app/features/leads/lead_activity_model.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/today/today_controller.dart';
import 'package:hitech_crm_app/features/today/today_model.dart';
import 'package:hitech_crm_app/features/today/today_repository.dart';
import 'package:hitech_crm_app/features/today/today_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

final _now = DateTime(2026, 10, 20, 9, 15); // Tuesday morning

CrmTask _task(String name, String lead, DateTime due, {String? description}) =>
    CrmTask(
      name: name,
      title: CrmTask.followUpTitle,
      status: 'Todo',
      dueDate: due,
      referenceDocname: lead,
      description: description,
    );

CrmLead _lead(String name, {DateTime? creation, String status = 'New'}) =>
    CrmLead(
      name: name,
      leadName: 'Lead $name',
      mobileNo: '98400 0000${name.length}',
      source: 'Walk-in',
      status: status,
      creation: creation,
    );

class FakeTodayRepository extends TodayRepository {
  FakeTodayRepository({this.failWith});

  AppError? failWith;
  int calls = 0;
  List<Iterable<String>> lookups = [];

  List<CrmTask> tasks = [
    _task('T1', 'L1', DateTime(2026, 10, 18, 11)), // 2 days late
    _task(
      'T2',
      'L2',
      DateTime(2026, 10, 20, 10, 30),
      description: 'Site visit',
    ),
    _task('T3', 'L1', DateTime(2026, 10, 20, 15)), // L1 again → dropped
    _task('T4', 'L3', DateTime(2026, 10, 19, 23, 59)), // yesterday → overdue
  ];
  List<CrmLead> newLeads = [
    _lead('L2', creation: DateTime(2026, 10, 19)), // has a task → dropped
    _lead('L8', creation: DateTime(2026, 10, 17)),
    _lead('L9', creation: DateTime(2026, 10, 19, 18)),
  ];

  @override
  Future<List<CrmTask>> fetchDueTasks(DateTime now) async {
    calls++;
    if (failWith != null) throw AppException(failWith!);
    return tasks;
  }

  @override
  Future<List<CrmLead>> fetchNewLeads() async => newLeads;

  @override
  Future<Map<String, CrmLead>> fetchLeadsByName(Iterable<String> names) async {
    lookups.add(names);
    return {for (final n in names.toSet()) n: _lead(n, status: 'Contacted')};
  }
}

Widget _app(Widget home, Locale locale) => MaterialApp(
  theme: AppTheme.light,
  builder: AppTheme.clampTextScale,
  locale: locale,
  supportedLocales: const [Locale('ta'), Locale('en')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  group('buildTodayItems', () {
    test('orders overdue → today → new and removes duplicates', () {
      final repo = FakeTodayRepository();
      final items = buildTodayItems(
        tasks: repo.tasks,
        leadsByName: {
          for (final n in ['L1', 'L2', 'L3']) n: _lead(n),
        },
        newLeads: repo.newLeads,
        now: _now,
      );

      expect(items.map((i) => '${i.type.name}:${i.lead.name}'), [
        'overdue:L1', // oldest overdue first
        'overdue:L3',
        'dueToday:L2',
        'newLead:L9', // newest new lead first
        'newLead:L8',
      ]);
      expect(items.first.daysLate(_now), 2);
      expect(items[1].daysLate(_now), 1);
    });

    test('task for an unknown lead still shows with its id', () {
      final items = buildTodayItems(
        tasks: [_task('T', 'CRM-LEAD-404', DateTime(2026, 10, 20, 12))],
        leadsByName: const {},
        newLeads: const [],
        now: _now,
      );
      expect(items.single.lead.name, 'CRM-LEAD-404');
      expect(items.single.type, TodayItemType.dueToday);
    });
  });

  group('TodayController', () {
    test('counts, badge total and filter', () async {
      final repo = FakeTodayRepository();
      final c = TodayController(repository: repo, clock: () => _now);
      await c.load();

      expect(c.total, 5);
      expect(c.count(TodayItemType.overdue), 2);
      expect(c.count(TodayItemType.dueToday), 1);
      expect(c.count(TodayItemType.newLead), 2);
      expect(c.pendingCalls, 3);
      expect(repo.lookups.single.toSet(), {'L1', 'L2', 'L3'});

      c.setFilter(TodayItemType.newLead);
      expect(c.visibleItems.map((i) => i.lead.name), ['L9', 'L8']);
    });

    test('concurrent refreshes share one request', () async {
      final repo = FakeTodayRepository();
      final c = TodayController(repository: repo, clock: () => _now);
      await Future.wait([c.refresh(), c.refresh(), c.refresh()]);
      expect(repo.calls, 1);
    });

    test('error before first load; data kept on a later failure', () async {
      final repo = FakeTodayRepository(failWith: AppError.network);
      final c = TodayController(repository: repo, clock: () => _now);
      await c.load();
      expect(c.hasLoaded, isFalse);
      expect(c.error, AppError.network);

      repo.failWith = null;
      await c.load();
      expect(c.total, 5);

      repo.failWith = AppError.server;
      expect(await c.refresh(), AppError.server);
      expect(c.total, 5);
    });
  });

  for (final locale in const [Locale('ta'), Locale('en')]) {
    testWidgets(
      'Today screen on Pixel 7 at large text (${locale.languageCode})',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final c = TodayController(
          repository: FakeTodayRepository(),
          clock: () => _now,
        );
        addTearDown(c.dispose);
        await c.load();
        await tester.pumpWidget(_app(TodayScreen(controller: c), locale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final ta = locale.languageCode == 'ta';
        expect(find.text(ta ? '2 நாள் தாமதம்' : '2 days late'), findsOneWidget);
        expect(find.text(ta ? '1 நாள் தாமதம்' : '1 day late'), findsOneWidget);
        expect(find.text('10:30'), findsOneWidget);
        expect(find.text('Site visit'), findsOneWidget);
        expect(find.text(ta ? 'அனைத்தும் (5)' : 'All (5)'), findsOneWidget);

        final newChip = find.text(ta ? 'புதியவை (2)' : 'New (2)');
        await tester.ensureVisible(newChip);
        await tester.pumpAndSettle();
        await tester.tap(newChip);
        await tester.pumpAndSettle();
        expect(find.text('Lead L1'), findsNothing);
        expect(find.text('Lead L9'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty state', (tester) async {
    final repo = FakeTodayRepository()
      ..tasks = []
      ..newLeads = [];
    final c = TodayController(repository: repo, clock: () => _now);
    addTearDown(c.dispose);
    await c.load();
    await tester.pumpWidget(
      _app(TodayScreen(controller: c), const Locale('ta')),
    );
    await tester.pumpAndSettle();
    expect(find.text('இன்று அழைக்க யாரும் இல்லை'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
