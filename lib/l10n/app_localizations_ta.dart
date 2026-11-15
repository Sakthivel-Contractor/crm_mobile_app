// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'HI Tech CRM';

  @override
  String get appSubtitle => 'கிணறு ஒப்பந்ததாரர்';

  @override
  String get serverUrl => 'சர்வர் URL';

  @override
  String get serverUrlHint => 'https://crm.example.com';

  @override
  String get username => 'மின்னஞ்சல் / பயனர் பெயர்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get showPassword => 'காட்டு';

  @override
  String get hidePassword => 'மறை';

  @override
  String get loginButton => 'உள்நுழை';

  @override
  String get fieldRequired => 'இது தேவை';

  @override
  String get errorServerUnreachable =>
      'சர்வரை அணுக முடியவில்லை. URL-ஐ சரிபார்க்கவும்.';

  @override
  String get errorWrongPassword => 'தவறான பயனர் பெயர் அல்லது கடவுச்சொல்';

  @override
  String get errorNoInternet => 'இணைய இணைப்பை சரிபார்க்கவும்';

  @override
  String get errorUnknown =>
      'உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String welcomeUser(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get logout => 'வெளியேறு';

  @override
  String get logoutConfirm => 'வெளியேறவா?';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageEnglish => 'EN';

  @override
  String get loginTitle => 'உள்நுழைக';

  @override
  String get loginHint => 'உங்கள் கணக்கில் உள்நுழையவும்';

  @override
  String get brandTagline =>
      'கிணறு பணிகள், வாடிக்கையாளர்கள், கட்டணங்கள் — ஒரே இடத்தில்';

  @override
  String serverSummary(String host) {
    return 'சர்வர்: $host';
  }

  @override
  String get changeServer => 'மாற்று';

  @override
  String get footerCopyright => '© HI Tech Open Well Contractor';

  @override
  String footerWithVersion(String version) {
    return '© HI Tech Open Well Contractor · பதிப்பு $version';
  }

  @override
  String get tabToday => 'இன்று';

  @override
  String get tabLeads => 'லீட்கள்';

  @override
  String get tabVisits => 'இட ஆய்வு';

  @override
  String get tabProfile => 'சுயவிவரம்';

  @override
  String get comingSoon => 'விரைவில் வருகிறது';

  @override
  String get comingSoonHint => 'இந்தப் பகுதி அடுத்த பதிப்பில் வரும்.';

  @override
  String get leadsTitle => 'லீட்கள்';

  @override
  String get search => 'தேடு';

  @override
  String get closeSearch => 'தேடலை மூடு';

  @override
  String get searchLeadsHint => 'பெயர் அல்லது மொபைல் எண்';

  @override
  String get filterAll => 'அனைத்தும்';

  @override
  String get noLeads => 'லீட் எதுவும் இல்லை';

  @override
  String get noLeadsHint => 'வேறு வடிகட்டி அல்லது தேடலை முயற்சிக்கவும்.';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get loginAgain => 'மீண்டும் உள்நுழை';

  @override
  String get errorUnauthorized =>
      'அமர்வு காலாவதியானது அல்லது அனுமதி இல்லை. மீண்டும் உள்நுழையவும்.';

  @override
  String get errorServer =>
      'சர்வரில் பிழை. சிறிது நேரம் கழித்து முயற்சிக்கவும்.';

  @override
  String get errorGeneric => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loadMoreFailed => 'மேலும் ஏற்ற முடியவில்லை';

  @override
  String get newLead => 'புதிய லீட்';

  @override
  String get newLeadDetails => 'லீட் விவரங்கள்';

  @override
  String get leadCreated => 'லீட் உருவாக்கப்பட்டது';

  @override
  String get firstName => 'முதல் பெயர் *';

  @override
  String get lastName => 'கடைசி பெயர்';

  @override
  String get mobileNumber => 'கைபேசி எண்';

  @override
  String get emailAddress => 'மின்னஞ்சல் முகவரி';

  @override
  String get village => 'கிராமம்';

  @override
  String get district => 'மாவட்டம்';

  @override
  String get workType => 'வேலை வகை';

  @override
  String get workTypeNewWell => 'புதிய கிணறு';

  @override
  String get workTypeDeepening => 'கிணறு ஆழப்படுத்தல்';

  @override
  String get workTypeWall => 'சுவர் கட்டுமானம்';

  @override
  String get workTypeDesilting => 'தூர்வாருதல்';

  @override
  String get workTypeSurvey => 'நீர் ஆய்வு';

  @override
  String get invalidPhone => 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get invalidEmail => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get unnamedLead => 'பெயரில்லா லீட்';

  @override
  String get leadDetailComingSoon => 'முழு விவரங்கள் அடுத்த பதிப்பில் வரும்.';

  @override
  String get timeJustNow => 'இப்போது';

  @override
  String timeMinutesAgo(int count) {
    return '$count நிமிடம் முன்';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count மணி நேரம் முன்';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count நாள் முன்';
  }

  @override
  String get statusNew => 'புதியது';

  @override
  String get statusContacted => 'தொடர்பு கொண்டது';

  @override
  String get statusNurture => 'பின்தொடர்தல்';

  @override
  String get statusQualified => 'தகுதியானது';

  @override
  String get statusUnqualified => 'தகுதியற்றது';

  @override
  String get statusJunk => 'பயனற்றது';

  @override
  String get profileServer => 'சர்வர்';

  @override
  String get profileLanguage => 'மொழி';

  @override
  String get profileVersion => 'பதிப்பு';

  @override
  String get callAction => 'அழை';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String get couldNotOpenApp => 'செயலியைத் திறக்க முடியவில்லை';

  @override
  String get leadStatusSection => 'நிலை';

  @override
  String changeStatusConfirm(String status) {
    return 'நிலையை \"$status\" என மாற்றவா?';
  }

  @override
  String get statusUpdated => 'நிலை புதுப்பிக்கப்பட்டது';

  @override
  String get logCallTitle => 'அழைப்பைப் பதிவு செய்';

  @override
  String get callOutcome => 'அழைப்பு முடிவு';

  @override
  String get outcomeTalked => 'பேசியாச்சு';

  @override
  String get outcomeNoAnswer => 'எடுக்கவில்லை';

  @override
  String get outcomeBusy => 'பிஸி';

  @override
  String get outcomeWrongNumber => 'தவறான எண்';

  @override
  String get outcomeRequired => 'அழைப்பு முடிவைத் தேர்ந்தெடுக்கவும்';

  @override
  String get callNoteLabel => 'குறிப்பு (விருப்பம்)';

  @override
  String get callNoteHint => 'என்ன பேசினீர்கள்?';

  @override
  String get nextFollowUp => 'அடுத்த பின்தொடர்தல்';

  @override
  String get changeFollowUp => 'தேதி/நேரத்தை மாற்று';

  @override
  String get noFollowUpForWrongNumber =>
      'தவறான எண்ணுக்கு பின்தொடர்தல் உருவாக்கப்படாது.';

  @override
  String get save => 'சேமி';

  @override
  String get saved => 'சேமிக்கப்பட்டது';

  @override
  String get upcomingFollowUp => 'வரவிருக்கும் பின்தொடர்தல்';

  @override
  String get overdue => 'தாமதம்';

  @override
  String get noUpcomingFollowUp => 'திட்டமிட்ட பின்தொடர்தல் இல்லை';

  @override
  String get noDueDate => 'தேதி இல்லை';

  @override
  String get historyTitle => 'வரலாறு';

  @override
  String get noNotes => 'இன்னும் குறிப்புகள் இல்லை';

  @override
  String callNoteTitle(String outcome) {
    return 'அழைப்பு: $outcome';
  }

  @override
  String get followUpTaskTitle => 'பின்தொடர் அழைப்பு';

  @override
  String get statTotal => 'மொத்தம்';

  @override
  String get statNew => 'புதியவை';

  @override
  String get filterDueToday => 'இன்று';

  @override
  String chipWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String daysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாள் தாமதம்',
      one: '1 நாள் தாமதம்',
    );
    return '$_temp0';
  }

  @override
  String get newBadge => 'புதிய';

  @override
  String get noCallsToday => 'இன்று அழைக்க யாரும் இல்லை';

  @override
  String get noCallsTodayHint => 'எல்லாம் முடிந்தது!';

  @override
  String todayPendingCount(int count) {
    return '$count அழைப்புகள் நிலுவையில்';
  }

  @override
  String get offlineBanner =>
      'இணைய இணைப்பு இல்லை. நீங்கள் இன்னும் உள்நுழைந்தே உள்ளீர்கள்.';

  @override
  String get tabDashboard => 'டாஷ்போர்டு';

  @override
  String get periodToday => 'இன்று';

  @override
  String get periodWeek => 'இந்த வாரம்';

  @override
  String get periodMonth => 'இந்த மாதம்';

  @override
  String get periodCustom => 'தனிப்பயன்';

  @override
  String dateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get kpiTotalLeads => 'மொத்த லீட்கள்';

  @override
  String get kpiSiteVisits => 'இட ஆய்வுகள்';

  @override
  String get kpiCallsLogged => 'பதிவான அழைப்புகள்';

  @override
  String get kpiOverdue => 'தாமதமான பின்தொடர்தல்கள்';

  @override
  String get kpiUnavailable => 'கிடைக்கவில்லை';

  @override
  String get chartFunnel => 'லீட் நிலைகள்';

  @override
  String get chartSource => 'மூலம் வாரியாக';

  @override
  String get chartDistrict => 'மாவட்டம் வாரியாக';

  @override
  String get chartOther => 'மற்றவை';

  @override
  String get chartNotSet => 'குறிப்பிடப்படவில்லை';

  @override
  String get chartNoData => 'இந்தக் காலத்தில் தரவு இல்லை';

  @override
  String get chartUnavailable => 'இந்தத் தகவல் சர்வரில் இல்லை';

  @override
  String barValue(int count, int percent) {
    return '$count ($percent%)';
  }

  @override
  String updatedAt(String time) {
    return 'புதுப்பிக்கப்பட்டது $time';
  }

  @override
  String filterSourceChip(String value) {
    return 'மூலம்: $value';
  }

  @override
  String filterDistrictChip(String value) {
    return 'மாவட்டம்: $value';
  }

  @override
  String get clearFilter => 'வடிகட்டியை நீக்கு';

  @override
  String get errorInsecureUrl => 'பாதுகாப்பான https:// முகவரியை உள்ளிடவும்';

  @override
  String get blockScreenshots => 'விவரத் திரையில் ஸ்கிரீன்ஷாட்டைத் தடு';

  @override
  String get blockScreenshotsHint =>
      'வாடிக்கையாளர் விவரங்களை ஸ்கிரீன்ஷாட் மற்றும் திரைப் பதிவிலிருந்து பாதுகாக்கும்';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get notificationsOn => 'இயக்கத்தில்';

  @override
  String get notificationsOff => 'முடக்கத்தில்';

  @override
  String get openSettings => 'அமைப்புகள்';

  @override
  String get channelNewLeads => 'புதிய லீட்கள்';

  @override
  String get channelNewLeadsDescription => 'புதிய லீட் வந்தவுடன் தெரிவிக்கும்';

  @override
  String get notificationsOffTitle => 'அறிவிப்புகள் முடக்கப்பட்டுள்ளன';

  @override
  String get notificationsOffBody =>
      'புதிய லீட்கள் வந்தவுடன் தெரிந்துகொள்ள அறிவிப்புகளை இயக்கவும்.';

  @override
  String get enableNotifications => 'அறிவிப்புகளை இயக்கு';

  @override
  String get dismiss => 'மூடு';

  @override
  String get appLock => 'செயலி பூட்டு';

  @override
  String get appLockHint => 'செயலியைத் திறக்கும்போது PIN கேட்கும்';

  @override
  String get useBiometric => 'கைரேகை மூலம் திற';

  @override
  String get useBiometricHint =>
      'PIN-க்குப் பதிலாக கைரேகை அல்லது முகத்தைப் பயன்படுத்தலாம்';

  @override
  String get changePin => 'PIN-ஐ மாற்று';

  @override
  String get change => 'மாற்று';

  @override
  String createPinTitle(int length) {
    return '$length இலக்க PIN-ஐ அமைக்கவும்';
  }

  @override
  String get confirmPinTitle => 'PIN-ஐ மீண்டும் உள்ளிடவும்';

  @override
  String get pinMismatch => 'PIN பொருந்தவில்லை. மீண்டும் அமைக்கவும்.';

  @override
  String get enterCurrentPin => 'தற்போதைய PIN-ஐ உள்ளிடவும்';

  @override
  String get unlockTitle => 'திறக்க PIN-ஐ உள்ளிடவும்';

  @override
  String wrongPin(int count) {
    return 'தவறான PIN. இன்னும் $count முறை முயலலாம்';
  }

  @override
  String pinBlocked(int seconds) {
    return 'பல முறை தவறு. $seconds வினாடிகளில் மீண்டும் முயலவும்';
  }

  @override
  String get forgotPin => 'PIN மறந்துவிட்டதா?';

  @override
  String get forgotPinBody =>
      'நீங்கள் வெளியேற்றப்படுவீர்கள். உங்கள் கடவுச்சொல்லுடன் மீண்டும் உள்நுழைந்து புதிய PIN-ஐ அமைக்கலாம்.';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get biometricPromptTitle => 'HI Tech CRM-ஐத் திற';

  @override
  String get biometricPromptReason => 'இது நீங்கள்தான் என உறுதிசெய்யவும்';

  @override
  String get biometricButton => 'கைரேகையைப் பயன்படுத்து';

  @override
  String get biometricLockedOut =>
      'கைரேகை தற்காலிகமாகப் பூட்டப்பட்டது. PIN-ஐப் பயன்படுத்தவும்.';

  @override
  String get biometricNotAvailable => 'இந்த போனில் கைரேகை அமைக்கப்படவில்லை';

  @override
  String get biometricFailed => 'கைரேகை உறுதிசெய்யப்படவில்லை';

  @override
  String get deleteDigit => 'நீக்கு';

  @override
  String pinDigitsEntered(int count, int total) {
    return '$total இல் $count இலக்கங்கள்';
  }

  @override
  String get appLockOn => 'செயலி பூட்டு இயக்கப்பட்டது';

  @override
  String get pinChanged => 'PIN மாற்றப்பட்டது';
}
