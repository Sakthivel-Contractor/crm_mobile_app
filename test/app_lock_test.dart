import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/app/theme.dart';
import 'package:hitech_crm_app/core/app_lock.dart';
import 'package:hitech_crm_app/core/storage.dart';
import 'package:hitech_crm_app/features/lock/app_lock_gate.dart';
import 'package:hitech_crm_app/features/lock/pin_setup_screen.dart';
import 'package:hitech_crm_app/l10n/app_localizations.dart';

final lock = AppLock.instance;

/// Moves the lock's clock forward.
DateTime _now = DateTime(2026, 1, 1);
void _advance(Duration d) => _now = _now.add(d);

Future<void> _wrong(int times) async {
  for (var i = 0; i < times; i++) {
    lock.blockedFor == null ? null : _advance(const Duration(hours: 1));
    expect(await lock.checkPin('0000'), isNot(PinCheck.ok));
  }
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: const [Locale('ta'), Locale('en')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => AppLockGate(child: child!),
  home: home,
);

/// Pixel 7 portrait.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tapPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.bySemanticsLabel(d).first);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    AppLock.iterations = 10; // fast hashing in tests
    AppLock.now = () => _now;
    await lock.disable();
  });

  group('AppLock', () {
    test('off by default; a set PIN starts the next run locked', () async {
      await lock.load();
      expect(lock.enabled, isFalse);
      expect(lock.locked, isFalse);

      await lock.setPin('4826');
      expect(lock.enabled, isTrue);
      expect(lock.locked, isFalse);

      await lock.load(); // next app start
      expect(lock.locked, isTrue);
      expect(await lock.checkPin('1111'), PinCheck.wrong);
      expect(lock.locked, isTrue);
      expect(await lock.checkPin('4826'), PinCheck.ok);
      expect(lock.locked, isFalse);
    });

    test('only a salted hash is stored, never the PIN', () async {
      await lock.setPin('4826');
      final stored = await AppStorage.secure.readAll();
      expect(stored.values.join(), isNot(contains('4826')));
      final record = stored['app_lock_pin']!;
      expect(record, startsWith('v1:10:'));

      // Same PIN again → different salt → different record.
      await lock.setPin('4826');
      expect(
        (await AppStorage.secure.readAll())['app_lock_pin'],
        isNot(record),
      );
    });

    test('wait after 5 wrong PINs; sign out after 10', () async {
      await lock.setPin('4826');
      await _wrong(4);
      expect(lock.attemptsBeforeWait, 1);
      expect(await lock.checkPin('0000'), PinCheck.blocked);
      expect(lock.blockedFor, const Duration(seconds: 30));

      // Even the right PIN is refused while waiting.
      expect(await lock.checkPin('4826'), PinCheck.blocked);
      _advance(const Duration(seconds: 31));
      expect(lock.blockedFor, isNull);

      await _wrong(4);
      expect(await lock.checkPin('0000'), PinCheck.signOut);
    });

    test('wrong-PIN count survives a restart', () async {
      await lock.setPin('4826');
      await _wrong(5);
      await lock.load();
      expect(lock.blockedFor, isNotNull);
    });

    test('right PIN resets the count', () async {
      await lock.setPin('4826');
      await _wrong(3);
      expect(await lock.checkPin('4826'), PinCheck.ok);
      expect(lock.attemptsBeforeWait, AppLock.failuresBeforeWait);
    });

    test('relocks only after a minute in the background', () async {
      await lock.setPin('4826');
      lock.didChangeAppLifecycleState(AppLifecycleState.paused);
      _advance(const Duration(seconds: 20));
      lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(lock.locked, isFalse);

      lock.didChangeAppLifecycleState(AppLifecycleState.paused);
      _advance(AppLock.relockAfter);
      lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(lock.locked, isTrue);
    });

    test('disable (also used on sign-out) forgets everything', () async {
      await lock.setPin('4826');
      await lock.setBiometricEnabled(true);
      await _wrong(2);
      await lock.disable();
      expect(lock.enabled, isFalse);
      expect(lock.biometricEnabled, isFalse);
      expect(await AppStorage.secure.readAll(), isEmpty);
    });

    test('PIN format', () {
      expect(AppLock.isValidPin('0123'), isTrue);
      for (final bad in ['', '123', '12345', '12a4', '١٢٣٤']) {
        expect(AppLock.isValidPin(bad), isFalse, reason: bad);
      }
    });
  });

  group('lock screen', () {
    testWidgets('hides the app until the right PIN is entered', (tester) async {
      await lock.setPin('4826');
      lock.lockNow();
      await tester.pumpWidget(_app(const Scaffold(body: Text('SECRET'))));
      await tester.pumpAndSettle();

      expect(find.text('SECRET'), findsNothing);
      expect(find.text('Enter your PIN to unlock'), findsOneWidget);

      await _tapPin(tester, '1111');
      expect(find.text('Wrong PIN. 4 tries left'), findsOneWidget);
      expect(find.text('SECRET'), findsNothing);

      await _tapPin(tester, '4826');
      expect(find.text('SECRET'), findsOneWidget);
      expect(find.text('Enter your PIN to unlock'), findsNothing);
    });

    testWidgets('forgot PIN asks before logging out', (tester) async {
      _phone(tester);
      await lock.setPin('4826');
      lock.lockNow();
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot PIN?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You will be logged out'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your PIN to unlock'), findsOneWidget);
    });
  });

  testWidgets('keypad fits a short landscape screen', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await lock.setPin('4826');
    lock.lockNow();
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Enter your PIN to unlock'), findsOneWidget);
  });

  group('PIN setup', () {
    testWidgets('PIN must be entered twice the same', (tester) async {
      _phone(tester);
      bool? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const PinSetupScreen(mode: PinSetupMode.create),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Set a 4-digit PIN'), findsOneWidget);
      await _tapPin(tester, '1234');
      expect(find.text('Enter the PIN again'), findsOneWidget);
      await _tapPin(tester, '9999');
      expect(
        find.text('The PINs did not match. Set it again.'),
        findsOneWidget,
      );
      expect(lock.enabled, isFalse);

      await _tapPin(tester, '2580');
      await _tapPin(tester, '2580');
      expect(result, isTrue);
      expect(lock.enabled, isTrue);
      expect(await lock.checkPin('2580'), PinCheck.ok);
    });
  });
}
