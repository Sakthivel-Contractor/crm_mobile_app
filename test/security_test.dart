import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hitech_crm_app/core/api_client.dart';
import 'package:hitech_crm_app/core/contact_links.dart';
import 'package:hitech_crm_app/features/leads/lead_repository.dart';

/// Dart files under lib/, excluding generated localizations.
List<File> _libDartFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.replaceAll(r'\', '/').contains('lib/l10n/'))
        .toList();

String _path(File f) => f.path.replaceAll(r'\', '/');

const _nasty = [
  "O'Brien",
  'a"b',
  '50% off',
  '_under_score',
  '[["name","!=",""]]',
  '{"or": 1}',
  '<script>alert(1)</script>',
  r'back\slash',
  '%',
  '\u0000nul',
];

void main() {
  group('logging', () {
    test('no print/debugPrint in lib/ outside the debug-only logger', () {
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        if (_path(file).endsWith('lib/core/log.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//')) continue;
          if (RegExp(r'(^|[^\w.])(print|debugPrint)\(').hasMatch(line)) {
            offenders.add('${_path(file)}:${i + 1}: $line');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the logger only prints in debug builds', () {
      final source = File('lib/core/log.dart').readAsStringSync();
      expect(source, contains('if (kDebugMode) debugPrint('));
    });

    test('no trust-all certificates or request/response body logging', () {
      for (final file in _libDartFiles()) {
        final s = file.readAsStringSync();
        expect(
          s,
          isNot(contains('badCertificateCallback')),
          reason: _path(file),
        );
        expect(s, isNot(contains('HttpOverrides')), reason: _path(file));
        expect(s, isNot(contains('LogInterceptor')), reason: _path(file));
      }
    });

    test('Dio has connect and receive timeouts', () {
      final s = File('lib/core/api_client.dart').readAsStringSync();
      expect(s, contains('connectTimeout:'));
      expect(s, contains('receiveTimeout:'));
    });
  });

  group('Android config', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('backups disabled and network security config referenced', () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(
        manifest,
        contains(
          'android:networkSecurityConfig="@xml/network_security_config"',
        ),
      );
    });

    test('release network config forbids cleartext and user CAs', () {
      final config = File(
        'android/app/src/main/res/xml/network_security_config.xml',
      ).readAsStringSync();
      expect(config, contains('cleartextTrafficPermitted="false"'));
      expect(config, isNot(contains('cleartextTrafficPermitted="true"')));
      expect(config, isNot(contains('src="user"')));
    });

    test('backup rules exclude every domain', () {
      final rules = File(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ).readAsStringSync();
      for (final domain in ['root', 'file', 'database', 'sharedpref']) {
        expect(
          RegExp('<exclude domain="$domain"').allMatches(rules).length,
          2,
          reason: '$domain in cloud-backup and device-transfer',
        );
      }
    });

    test('only allowed permissions; only MainActivity exported', () {
      const allowed = {
        'android.permission.INTERNET',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.CAMERA',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
      };
      final used = RegExp(r'uses-permission android:name="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1))
          .toSet();
      expect(allowed.containsAll(used), isTrue, reason: '$used');

      final exported = RegExp(
        r'<activity[^>]*android:name="([^"]+)"[^>]*android:exported="true"',
        dotAll: true,
      ).allMatches(manifest).map((m) => m.group(1)).toList();
      expect(exported, ['.MainActivity']);
    });

    test('release build shrinks and minifies', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('isMinifyEnabled = true'));
      expect(gradle, contains('isShrinkResources = true'));
      expect(gradle, contains('"proguard-rules.pro"'));
    });

    test('signing secrets stay out of the repo', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      // Values come only from android/key.properties.
      expect(gradle, contains('rootProject.file("key.properties")'));
      expect(gradle, isNot(contains('storePassword = "')));
      expect(gradle, isNot(contains('keyPassword = "')));
      final ignore = File('android/.gitignore').readAsLinesSync();
      for (final rule in ['key.properties', '**/*.jks', '**/*.keystore']) {
        expect(ignore, contains(rule), reason: rule);
      }
    });

    test('R8 keeps the JNI classes shared_preferences needs', () {
      // Without these, every SharedPreferences call fails in release builds.
      final rules = File('android/app/proguard-rules.pro').readAsStringSync();
      for (final keep in [
        'io.flutter.plugins.sharedpreferences.**',
        'kotlin.Unit',
        'kotlin.coroutines.Continuation',
        'kotlin.enums.EnumEntries',
        'kotlin.jvm.internal.DefaultConstructorMarker',
      ]) {
        expect(rules, contains('-keep class $keep'), reason: keep);
      }
    });
  });

  group('site URL policy', () {
    test('release builds accept only https', () {
      for (final url in [
        'http://crm.example.com',
        'http://localhost:5000',
        'http://10.0.2.2:8000',
        'ftp://crm.example.com',
        'https://user:pass@crm.example.com',
        'https://',
        'not a url',
      ]) {
        expect(
          ApiClient.isAllowedSiteUrl(url, release: true),
          isFalse,
          reason: url,
        );
      }
      expect(
        ApiClient.isAllowedSiteUrl('https://crm.example.com', release: true),
        isTrue,
      );
    });

    test('debug builds also allow http to localhost/emulator only', () {
      expect(
        ApiClient.isAllowedSiteUrl('http://localhost:5000', release: false),
        isTrue,
      );
      expect(
        ApiClient.isAllowedSiteUrl('http://10.0.2.2:8000', release: false),
        isTrue,
      );
      expect(
        ApiClient.isAllowedSiteUrl('http://crm.example.com', release: false),
        isFalse,
      );
      expect(
        ApiClient.isAllowedSiteUrl('http://localhost.evil.com', release: false),
        isFalse,
      );
    });

    test('typed URLs without a scheme become https', () {
      expect(
        ApiClient.isAllowedSiteUrl(
          ApiClient.normalizeUrl('crm.example.com'),
          release: true,
        ),
        isTrue,
      );
    });

    test('normalization retains userinfo for the URL policy to reject', () {
      for (final input in [
        'https://user:pass@crm.example.com/path',
        'user:pass@crm.example.com/path',
      ]) {
        final normalized = ApiClient.normalizeUrl(input);
        expect(ApiClient.isAllowedSiteUrl(normalized, release: true), isFalse);
      }
    });
  });

  group('phone validation and link builders', () {
    test('Indian mobile normalisation', () {
      for (final ok in [
        '9840012345',
        '+91 98400 12345',
        '+91-98400-12345',
        '09840012345',
        '919840012345',
      ]) {
        expect(normalizeIndianMobile(ok), '9840012345', reason: ok);
      }
      for (final bad in [
        '1234567890', // must start 6–9
        '98400',
        '98400123456789',
        '',
        '+1 202 555 0100',
        ..._nasty,
      ]) {
        expect(normalizeIndianMobile(bad), isNull, reason: bad);
      }
    });

    test('tel: links only from validated numbers', () {
      expect(telUri('+91 98400-12345').toString(), 'tel:+919840012345');
      expect(telUri('0422 2345678').toString(), 'tel:04222345678');
      for (final bad in [
        '12345',
        '9840012345;ext=1',
        '98400*#',
        'tel:9840012345',
        'javascript:alert(1)',
        ..._nasty,
      ]) {
        expect(telUri(bad), isNull, reason: bad);
      }
    });

    test('WhatsApp links are https://wa.me/91XXXXXXXXXX only', () {
      expect(
        whatsappUri('98400 12345').toString(),
        'https://wa.me/919840012345',
      );
      for (final bad in ['12345', '+1 202 555 0100', ..._nasty]) {
        expect(whatsappUri(bad), isNull, reason: bad);
      }
    });

    test('only app-built links may be opened', () {
      expect(isAllowedExternalUri(Uri.parse('tel:+919840012345')), isTrue);
      expect(
        isAllowedExternalUri(Uri.parse('https://wa.me/919840012345')),
        isTrue,
      );
      for (final bad in [
        'https://evil.com/919840012345',
        'https://wa.me/919840012345?text=hi',
        'http://wa.me/919840012345',
        'javascript:alert(1)',
        'intent://scan#Intent;end',
        'file:///etc/passwd',
        'tel:*#06#',
        'geo:0,0',
      ]) {
        expect(isAllowedExternalUri(Uri.parse(bad)), isFalse, reason: bad);
      }
    });
  });

  group('lead list query building', () {
    test('user text is only ever a filter value', () {
      for (final input in _nasty) {
        final query = LeadRepository.buildLeadListQuery(
          search: input,
          status: input,
          source: input,
          district: input,
        );
        final orFilters = jsonDecode(query['or_filters'] as String) as List;
        expect(orFilters, hasLength(2), reason: input);
        expect(orFilters[0], ['lead_name', 'like', '%${input.trim()}%']);
        expect(orFilters[1], ['mobile_no', 'like', '%${input.trim()}%']);

        final filters = jsonDecode(query['filters'] as String) as List;
        expect(filters, [
          ['status', '=', input],
          ['source', '=', input],
          [LeadRepository.districtField, '=', input],
        ], reason: input);
      }
    });

    test('search is length-limited and paging is bounded', () {
      final query = LeadRepository.buildLeadListQuery(
        search: 'x' * 500,
        start: -5,
        pageLength: 10000,
      );
      final term = (jsonDecode(query['or_filters'] as String) as List)[0][2];
      expect((term as String).length, LeadRepository.maxSearchLength + 2);
      expect(query['limit_start'], 0);
      expect(query['limit_page_length'], 100);
      expect(query.containsKey('filters'), isFalse);
    });
  });
}
