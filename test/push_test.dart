import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/core/push_service.dart';

void main() {
  group('PushService.leadFromData', () {
    test('new_lead messages give the lead name', () {
      expect(
        PushService.leadFromData({'type': 'new_lead', 'lead': 'CRM-LEAD-0042'}),
        'CRM-LEAD-0042',
      );
      expect(
        PushService.leadFromData({'type': 'new_lead', 'lead': '  CRM-LEAD-7 '}),
        'CRM-LEAD-7',
      );
    });

    test('anything else is ignored', () {
      for (final data in <Map<String, dynamic>>[
        {},
        {'type': 'promo', 'lead': 'CRM-LEAD-1'},
        {'type': 'new_lead'},
        {'type': 'new_lead', 'lead': ''},
        {'type': 'new_lead', 'lead': 42},
        {'type': 'new_lead', 'lead': 'x' * 141},
        {'type': 'new_lead', 'lead': 'CRM\nLEAD'},
      ]) {
        expect(PushService.leadFromData(data), isNull, reason: '$data');
      }
    });
  });

  group('PushService.leadFromPayload', () {
    test('reads the lead from a tapped local notification', () {
      expect(
        PushService.leadFromPayload('{"type":"new_lead","lead":"CRM-LEAD-9"}'),
        'CRM-LEAD-9',
      );
    });

    test('bad payloads are ignored', () {
      for (final payload in [
        null,
        '',
        'not json',
        '[1,2]',
        '"CRM-LEAD-9"',
        '{"type":"promo","lead":"CRM-LEAD-9"}',
        '{"type":"new_lead","lead":"a\u0000b"}',
      ]) {
        expect(PushService.leadFromPayload(payload), isNull, reason: payload);
      }
    });
  });

  test('the system prompt is shown only to users never asked', () {
    expect(PushService.shouldPrompt(AuthorizationStatus.notDetermined), isTrue);
    for (final status in [
      AuthorizationStatus.authorized,
      AuthorizationStatus.provisional,
      AuthorizationStatus.denied,
      AuthorizationStatus.deniedPermanently,
    ]) {
      expect(PushService.shouldPrompt(status), isFalse, reason: '$status');
    }
  });

  test('the FCM token is never logged', () {
    final source = File('lib/core/push_service.dart').readAsStringSync();
    final logLines = RegExp(r'logDebug\(([^;]*)\);')
        .allMatches(source)
        .map((m) => m.group(1)!);
    for (final line in logLines) {
      expect(line, isNot(contains(r'$token')), reason: line);
      expect(line, isNot(contains(r'${token')), reason: line);
      expect(line, isNot(contains(r'$_token')), reason: line);
    }
  });

  test('push is off before init and on non-Android platforms', () async {
    final push = PushService.instance;
    expect(push.enabled, isNull);
    expect(push.showPermissionCard, isFalse);
    // Not initialised: these must be safe no-ops.
    await push.registerDevice();
    await push.unregisterDevice();
    await push.refreshPermissionStatus();
    await push.retryRegistrationIfNeeded();
    await push.updateLanguage(const Locale('en'));
  });

  group('Android setup', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('permission, default channel and monochrome icon', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android:value="new_leads"'));
      expect(manifest, contains('@drawable/ic_stat_notify'));
      for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(
          File('android/app/src/main/res/drawable-$density/ic_stat_notify.png')
              .existsSync(),
          isTrue,
          reason: density,
        );
      }
    });

    test('Google Services plugin and desugaring are configured', () {
      final settings = File('android/settings.gradle.kts').readAsStringSync();
      final app = File('android/app/build.gradle.kts').readAsStringSync();
      expect(settings, contains('com.google.gms.google-services'));
      expect(app, contains('id("com.google.gms.google-services")'));
      expect(app, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(File('android/app/google-services.json').existsSync(), isTrue);
    });
  });
}
