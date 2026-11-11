import 'package:url_launcher/url_launcher.dart';

import 'log.dart';

/// Max length of any phone input we act on.
const int maxPhoneLength = 20;

/// A 10-digit Indian mobile number (starts with 6–9) from inputs like
/// "+91 98400-12345", "09840012345" or "9840012345"; otherwise null.
String? normalizeIndianMobile(String raw) {
  if (raw.length > maxPhoneLength) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? digits : null;
}

/// True for numbers the dialer can use: optional leading +, 6–15 digits,
/// and only spaces, dashes, dots or brackets as separators.
bool isDialablePhone(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.length > maxPhoneLength) return false;
  if (!RegExp(r'^\+?[\d\s\-().]+$').hasMatch(value)) return false;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 6 && digits.length <= 15;
}

/// `tel:` link built only from a validated number; null if invalid.
Uri? telUri(String phone) {
  if (!isDialablePhone(phone)) return null;
  final value = phone.trim();
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return Uri(scheme: 'tel', path: value.startsWith('+') ? '+$digits' : digits);
}

/// `https://wa.me/91XXXXXXXXXX` for a valid Indian mobile; null otherwise.
Uri? whatsappUri(String phone) {
  final mobile = normalizeIndianMobile(phone);
  if (mobile == null) return null;
  return Uri.https('wa.me', '/91$mobile');
}

/// Only links this app builds itself may be opened.
bool isAllowedExternalUri(Uri uri) =>
    (uri.scheme == 'tel' && RegExp(r'^\+?\d{6,15}$').hasMatch(uri.path)) ||
    (uri.scheme == 'https' &&
        uri.host == 'wa.me' &&
        RegExp(r'^/91[6-9]\d{9}$').hasMatch(uri.path) &&
        !uri.hasQuery);

/// Opens [uri] in the matching external app. Returns false on failure or if
/// the link is not one the app is allowed to open.
Future<bool> openExternal(Uri uri) async {
  if (!isAllowedExternalUri(uri)) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception catch (e) {
    logDebug('Opening link failed: $e');
    return false;
  }
}
