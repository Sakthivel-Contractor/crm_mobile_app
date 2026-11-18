import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/app_error.dart';
import 'package:hitech_crm_app/core/contact_links.dart';
import 'package:hitech_crm_app/features/leads/lead_activity_model.dart';
import 'package:hitech_crm_app/features/leads/lead_detail_controller.dart';
import 'package:hitech_crm_app/features/leads/lead_detail_screen.dart';
import 'package:hitech_crm_app/features/leads/lead_model.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

final _now = DateTime(2026, 10, 19, 15, 30);

class FakeDetailRepository extends LeadRepository {
  final log = <String>[];
  String status = 'New';
  List<CrmTask> tasks = [
    CrmTask(
      name: 'TASK-1',
      title: CrmTask.followUpTitle,
      status: 'Todo',
      dueDate: DateTime(2026, 10, 18, 10), // overdue
    ),
    const CrmTask(name: 'TASK-2', title: 'Site visit', status: 'Todo'),
    const CrmTask(name: 'TASK-3', title: CrmTask.followUpTitle, status: 'Done'),
  ];
  List<CrmNote> notes = [];

  /// Fail the next call whose log entry starts with this prefix.
  String? failOn;

  void _maybeFail(String entry) {
    log.add(entry);
    if (failOn != null && entry.startsWith(failOn!)) {
      failOn = null;
      throw const AppException(AppError.network);
    }
  }

  @override
  Future<CrmLead> getLead(String name) async => CrmLead(
    name: name,
    leadName: 'Ravi Kumar',
    mobileNo: '98400 12345',
    source: 'Walk-in',
    whenStart: 'Next month',
    status: status,
  );

  @override
  Future<List<CrmNote>> getNotes(String name) async => notes;

  @override
  Future<List<CrmTask>> getTasks(String name) async => tasks;

  @override
  Future<List<LeadStatus>> fetchStatuses() async => const [
    LeadStatus(name: 'New', color: 'gray'),
    LeadStatus(name: 'Contacted', color: 'orange'),
    LeadStatus(name: 'Qualified', color: 'green'),
  ];

  @override
  Future<void> updateStatus(String name, String status) async {
    _maybeFail('status:$status');
    this.status = status;
  }

  @override
  Future<void> addNote(String name, String title, String content) async {
    _maybeFail('note:$title:$content');
    notes = [
      CrmNote(name: 'N${notes.length}', title: title, content: content),
      ...notes,
    ];
  }

  @override
  Future<void> completeTask(String taskName) async =>
      _maybeFail('done:$taskName');

  @override
  Future<void> addFollowUp(String name, DateTime dueDate, String note) async =>
      _maybeFail('followup:${frappeDateTimeFormat.format(dueDate)}:$note');
}

LeadDetailController _controller(FakeDetailRepository repo) =>
    LeadDetailController(
      leadName: 'CRM-LEAD-1',
      repository: repo,
      clock: () => _now,
    );

void main() {
  group('LeadDetailController.saveCall', () {
    test('requires an outcome', () async {
      final repo = FakeDetailRepository();
      final c = _controller(repo);
      await c.load();

      final result = await c.saveCall('hello');
      expect(result.status, SaveCallStatus.invalid);
      expect(c.showOutcomeError, isTrue);
      expect(repo.log, isEmpty);
    });

    test('note → close open follow-ups → new follow-up', () async {
      final repo = FakeDetailRepository();
      final c = _controller(repo);
      await c.load();
      expect(c.followUp, DateTime(2026, 10, 20, 10)); // tomorrow 10:00

      c.selectOutcome(CallOutcome.talked);
      final result = await c.saveCall('  Wants a 6 ft well  ');

      expect(result.status, SaveCallStatus.saved);
      expect(repo.log, [
        'note:Call: Talked:Wants a 6 ft well',
        'done:TASK-1', // TASK-2 is not a follow-up, TASK-3 is already done
        'followup:2026-10-20 10:00:00:Wants a 6 ft well',
      ]);
      expect(c.outcome, isNull); // draft reset
      expect(c.notes.first.title, 'Call: Talked');
    });

    test('wrong number creates no follow-up', () async {
      final repo = FakeDetailRepository();
      final c = _controller(repo);
      await c.load();

      c.selectOutcome(CallOutcome.wrongNumber);
      expect(c.createsFollowUp, isFalse);
      await c.saveCall('');
      expect(repo.log, ['note:Call: Wrong number:', 'done:TASK-1']);
    });

    test('retry after a failure does not repeat finished steps', () async {
      final repo = FakeDetailRepository()..failOn = 'followup';
      final c = _controller(repo);
      await c.load();

      c.selectOutcome(CallOutcome.busy);
      final first = await c.saveCall('call later');
      expect(first.status, SaveCallStatus.failed);
      expect(first.error, AppError.network);

      final second = await c.saveCall('call later');
      expect(second.status, SaveCallStatus.saved);
      expect(repo.log.where((e) => e.startsWith('note:')).length, 1);
      expect(repo.log.where((e) => e.startsWith('done:')).length, 1);
      expect(repo.log.where((e) => e.startsWith('followup:')).length, 2);
    });

    test('next open task is the earliest due one', () async {
      final c = _controller(FakeDetailRepository());
      await c.load();
      expect(c.nextOpenTask?.name, 'TASK-1');
      expect(c.nextOpenTask!.isOverdue(_now), isTrue);
    });
  });

  group('contact links', () {
    test('WhatsApp numbers get the 91 prefix', () {
      expect(
        whatsappUri('98400 12345').toString(),
        'https://wa.me/919840012345',
      );
      expect(
        whatsappUri('09840012345').toString(),
        'https://wa.me/919840012345',
      );
      expect(
        whatsappUri('+91 98400-12345').toString(),
        'https://wa.me/919840012345',
      );
      expect(whatsappUri('—'), isNull);
    });

    test('tel keeps digits and +', () {
      expect(telUri('+91 98400-12345').toString(), 'tel:+919840012345');
    });
  });

  group('HTML content', () {
    test('round-trips plain text safely', () {
      final html = plainTextToHtml('a < b & c\nnext');
      expect(html, '<p>a &lt; b &amp; c<br>next</p>');
      expect(htmlToPlainText(html), 'a < b & c\nnext');
      expect(
        htmlToPlainText('<p>Hello</p><p>World&nbsp;!</p>'),
        'Hello\nWorld !',
      );
    });
  });

  testWidgets('detail screen renders all sections and saves a call', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = FakeDetailRepository();
    final controller = _controller(repo);
    addTearDown(controller.dispose);
    var changed = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ta'),
        supportedLocales: const [Locale('ta'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LeadDetailScreen(
          lead: const CrmLead(name: 'CRM-LEAD-1', leadName: 'Ravi Kumar'),
          controller: controller,
          onLeadChanged: () => changed++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('அழை'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('தாமதம்'), findsOneWidget); // overdue badge
    expect(find.text('தொடர்பு கொண்டது'), findsOneWidget); // status chip
    expect(find.text('எப்போது தொடங்கலாம்: Next month'), findsOneWidget);

    // Save without outcome → validation message.
    await tester.ensureVisible(find.text('சேமி'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('சேமி'));
    await tester.pump();
    expect(find.text('அழைப்பு முடிவைத் தேர்ந்தெடுக்கவும்'), findsOneWidget);

    await tester.ensureVisible(find.text('பேசியாச்சு'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('பேசியாச்சு'));
    await tester.pump();
    await tester.ensureVisible(find.text('சேமி'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('சேமி'));
    await tester.pumpAndSettle();

    expect(find.text('சேமிக்கப்பட்டது'), findsOneWidget);
    await tester.ensureVisible(find.text('அழைப்பு: பேசியாச்சு'));
    expect(find.text('அழைப்பு: பேசியாச்சு'), findsOneWidget); // in history
    expect(changed, 1);
  });
}
