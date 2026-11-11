import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/app_error.dart';
import 'package:hitech_crm_app/features/dashboard/dashboard_controller.dart';
import 'package:hitech_crm_app/features/dashboard/dashboard_model.dart';
import 'package:hitech_crm_app/features/dashboard/dashboard_repository.dart';
import 'package:hitech_crm_app/features/dashboard/dashboard_screen.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

final _now = DateTime(2026, 10, 22, 11, 45); // Thursday

class FakeDashboardRepository extends DashboardRepository {
  AppError? failTotal;
  bool noDistrictField = false;
  bool noSiteVisitDoctype = false;
  final ranges = <PeriodRange>[];

  @override
  Future<int> totalLeads(PeriodRange range) async {
    ranges.add(range);
    if (failTotal != null) throw AppException(failTotal!);
    return 40;
  }

  @override
  Future<List<GroupCount>> leadsByStatus(PeriodRange range) async => const [
    GroupCount('New', 18),
    GroupCount('Qualified', 12),
    GroupCount('Contacted', 10),
  ];

  @override
  Future<List<GroupCount>> leadsBySource(PeriodRange range) async => const [
    GroupCount('Website', 5),
    GroupCount('Facebook', 20),
    GroupCount(null, 3),
    GroupCount('Referral', 12),
  ];

  @override
  Future<List<GroupCount>> leadsByDistrict(PeriodRange range) async {
    if (noDistrictField) throw const AppException(AppError.server);
    return const [
      GroupCount('கோயம்புத்தூர்', 10),
      GroupCount('திருப்பூர்', 8),
      GroupCount('ஈரோடு', 6),
      GroupCount('சேலம்', 5),
      GroupCount('மதுரை', 4),
      GroupCount('திண்டுக்கல்', 3),
      GroupCount('கரூர்', 2),
      GroupCount('நாமக்கல்', 2),
    ];
  }

  @override
  Future<int> siteVisits(PeriodRange range) async {
    if (noSiteVisitDoctype) throw const AppException(AppError.server);
    return 7;
  }

  @override
  Future<int> callsLogged(PeriodRange range) async => 25;

  @override
  Future<int> overdueFollowUps(DateTime now) async => 4;
}

class FakeStatuses extends LeadRepository {
  @override
  Future<List<LeadStatus>> fetchStatuses() async => const [
    LeadStatus(name: 'New', color: 'gray', position: 1),
    LeadStatus(name: 'Contacted', color: 'orange', position: 2),
    LeadStatus(name: 'Nurture', color: 'blue', position: 3),
    LeadStatus(name: 'Qualified', color: 'green', position: 4),
  ];
}

DashboardController _controller(FakeDashboardRepository repo) =>
    DashboardController(
      repository: repo,
      leadRepository: FakeStatuses(),
      clock: () => _now,
    );

void main() {
  group('model', () {
    test('periods: today, week from Monday, month from the 1st', () {
      final today = PeriodRange.of(DashboardPeriod.today, _now);
      expect(today.start, DateTime(2026, 10, 22));
      expect(today.end, DateTime(2026, 10, 22, 23, 59, 59));
      expect(
        PeriodRange.of(DashboardPeriod.week, _now).start,
        DateTime(2026, 10, 19),
      );
      expect(
        PeriodRange.of(DashboardPeriod.month, _now).start,
        DateTime(2026, 10, 1),
      );
    });

    test('top 6 districts + Other', () {
      final groups = [for (var i = 1; i <= 8; i++) GroupCount('D$i', i)];
      final top = topWithOther(groups, 6);
      expect(top.map((g) => g.value), [
        'D8',
        'D7',
        'D6',
        'D5',
        'D4',
        'D3',
        null,
      ]);
      expect(top.last.isOther, isTrue);
      expect(top.last.count, 3); // D2 + D1
    });

    test('funnel follows status order and keeps zero statuses', () {
      final funnel = funnelOrder(
        const [
          GroupCount('Qualified', 3),
          GroupCount('New', 5),
          GroupCount('Lost', 1), // not in the status list
        ],
        const [
          LeadStatus(name: 'New'),
          LeadStatus(name: 'Contacted'),
          LeadStatus(name: 'Qualified'),
        ],
      );
      expect(funnel.map((g) => '${g.value}:${g.count}'), [
        'New:5',
        'Contacted:0',
        'Qualified:3',
        'Lost:1',
      ]);
    });
  });

  group('DashboardController', () {
    test('loads everything; optional sections may be unavailable', () async {
      final repo = FakeDashboardRepository()
        ..noDistrictField = true
        ..noSiteVisitDoctype = true;
      final c = _controller(repo);
      await c.load();

      expect(c.error, isNull);
      expect(c.data!.totalLeads, 40);
      expect(c.data!.siteVisits, isNull);
      expect(c.byDistrict, isNull);
      expect(c.data!.callsLogged, 25);
      expect(c.funnel.map((g) => g.value), [
        'New',
        'Contacted',
        'Nurture',
        'Qualified',
      ]);
      expect(c.bySource!.first.value, 'Facebook');
      expect(c.updatedAt, _now);
    });

    test('core failure → error; period change re-queries', () async {
      final repo = FakeDashboardRepository()..failTotal = AppError.network;
      final c = _controller(repo);
      await c.load();
      expect(c.hasLoaded, isFalse);
      expect(c.error, AppError.network);

      repo.failTotal = null;
      c.setPeriod(DashboardPeriod.week);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.ranges.last.start, DateTime(2026, 10, 19));
      expect(c.hasLoaded, isTrue);
    });
  });

  for (final locale in const [Locale('ta'), Locale('en')]) {
    testWidgets('dashboard fits on a 360px phone at large text '
        '(${locale.languageCode}) and bars open Leads', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final c = _controller(FakeDashboardRepository());
      addTearDown(c.dispose);
      await c.load();
      final opened = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: AppTheme.clampTextScale,
          locale: locale,
          supportedLocales: const [Locale('ta'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: DashboardScreen(
            controller: c,
            onOpenLeads: ({status, source, district}) =>
                opened.add('${status ?? ''}|${source ?? ''}|${district ?? ''}'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final ta = locale.languageCode == 'ta';
      expect(find.text('40'), findsOneWidget);
      expect(find.text('18 (45%)'), findsOneWidget); // New 18 of 40

      final qualified = find.text(ta ? 'தகுதியானது' : 'Qualified').last;
      await tester.ensureVisible(qualified);
      await tester.pumpAndSettle();
      await tester.tap(qualified);

      final facebook = find.text('Facebook');
      await tester.ensureVisible(facebook);
      await tester.pumpAndSettle();
      await tester.tap(facebook);

      final other = find.text(ta ? 'மற்றவை' : 'Other');
      await tester.ensureVisible(other);
      await tester.pumpAndSettle();
      await tester.tap(other); // not tappable
      await tester.tap(find.text('கோயம்புத்தூர்'));

      expect(opened, ['Qualified||', '|Facebook|', '||கோயம்புத்தூர்']);
      expect(
        find.textContaining(ta ? 'புதுப்பிக்கப்பட்டது' : 'Updated'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('5-tab bottom bar fits Tamil labels on a 360px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: AppTheme.clampTextScale,
        locale: const Locale('ta'),
        supportedLocales: const [Locale('ta'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              bottomNavigationBar: NavigationBar(
                destinations: [
                  for (final (icon, label) in [
                    (Icons.today_outlined, l10n.tabToday),
                    (Icons.people_alt_outlined, l10n.tabLeads),
                    (Icons.place_outlined, l10n.tabVisits),
                    (Icons.insights_outlined, l10n.tabDashboard),
                    (Icons.person_outline, l10n.tabProfile),
                  ])
                    NavigationDestination(icon: Icon(icon), label: label),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
