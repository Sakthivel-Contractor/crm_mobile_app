// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HI Tech CRM';

  @override
  String get appSubtitle => 'Open Well Contractor';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://crm.example.com';

  @override
  String get username => 'Email / Username';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get loginButton => 'Login';

  @override
  String get fieldRequired => 'Required';

  @override
  String get errorServerUnreachable =>
      'Cannot reach the server. Check the URL.';

  @override
  String get errorWrongPassword => 'Wrong username or password';

  @override
  String get errorNoInternet => 'Check your internet connection';

  @override
  String get errorUnknown => 'Login failed. Please try again.';

  @override
  String welcomeUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Logout now?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageEnglish => 'EN';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginHint => 'Sign in to your account';

  @override
  String get brandTagline =>
      'Well jobs, customers and payments — all in one place';

  @override
  String serverSummary(String host) {
    return 'Server: $host';
  }

  @override
  String get changeServer => 'Change';

  @override
  String get footerCopyright => '© HI Tech Open Well Contractor';

  @override
  String footerWithVersion(String version) {
    return '© HI Tech Open Well Contractor · Version $version';
  }

  @override
  String get tabToday => 'Today';

  @override
  String get tabLeads => 'Leads';

  @override
  String get tabVisits => 'Visits';

  @override
  String get tabProfile => 'Profile';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonHint => 'This section is coming in a future update.';

  @override
  String get leadsTitle => 'Leads';

  @override
  String get search => 'Search';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchLeadsHint => 'Name or mobile number';

  @override
  String get filterAll => 'All';

  @override
  String get noLeads => 'No leads found';

  @override
  String get noLeadsHint => 'Try a different filter or search.';

  @override
  String get retry => 'Retry';

  @override
  String get loginAgain => 'Log in again';

  @override
  String get errorUnauthorized =>
      'Your session has expired or you don\'t have access. Please log in again.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get loadMoreFailed => 'Couldn\'t load more';

  @override
  String get newLead => 'New lead';

  @override
  String get newLeadDetails => 'Lead details';

  @override
  String get leadCreated => 'Lead created';

  @override
  String get firstName => 'First name *';

  @override
  String get lastName => 'Last name';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get emailAddress => 'Email address';

  @override
  String get village => 'Village';

  @override
  String get district => 'District';

  @override
  String get workType => 'Work type';

  @override
  String get workTypeNewWell => 'New well';

  @override
  String get workTypeDeepening => 'Well deepening';

  @override
  String get workTypeWall => 'Wall construction';

  @override
  String get workTypeDesilting => 'Desilting';

  @override
  String get workTypeSurvey => 'Water survey';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get unnamedLead => 'Unnamed lead';

  @override
  String get leadDetailComingSoon =>
      'Full lead details are coming in the next update.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get statusNew => 'New';

  @override
  String get statusContacted => 'Contacted';

  @override
  String get statusNurture => 'Nurture';

  @override
  String get statusQualified => 'Qualified';

  @override
  String get statusUnqualified => 'Unqualified';

  @override
  String get statusJunk => 'Junk';

  @override
  String get profileServer => 'Server';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileVersion => 'Version';

  @override
  String get callAction => 'Call';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String get couldNotOpenApp => 'Couldn\'t open the app';

  @override
  String get leadStatusSection => 'Status';

  @override
  String changeStatusConfirm(String status) {
    return 'Change status to \"$status\"?';
  }

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get logCallTitle => 'Log a call';

  @override
  String get callOutcome => 'Call outcome';

  @override
  String get outcomeTalked => 'Talked';

  @override
  String get outcomeNoAnswer => 'No answer';

  @override
  String get outcomeBusy => 'Busy';

  @override
  String get outcomeWrongNumber => 'Wrong number';

  @override
  String get outcomeRequired => 'Choose a call outcome';

  @override
  String get callNoteLabel => 'Note (optional)';

  @override
  String get callNoteHint => 'What was discussed?';

  @override
  String get nextFollowUp => 'Next follow-up';

  @override
  String get changeFollowUp => 'Change date and time';

  @override
  String get noFollowUpForWrongNumber =>
      'No follow-up is created for a wrong number.';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get upcomingFollowUp => 'Upcoming follow-up';

  @override
  String get overdue => 'Overdue';

  @override
  String get noUpcomingFollowUp => 'No follow-up scheduled';

  @override
  String get noDueDate => 'No due date';

  @override
  String get historyTitle => 'History';

  @override
  String get noNotes => 'No notes yet';

  @override
  String callNoteTitle(String outcome) {
    return 'Call: $outcome';
  }

  @override
  String get followUpTaskTitle => 'Follow-up call';

  @override
  String get statTotal => 'Total';

  @override
  String get statNew => 'New';

  @override
  String get filterDueToday => 'Today';

  @override
  String chipWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String daysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get newBadge => 'New';

  @override
  String get noCallsToday => 'No calls for today';

  @override
  String get noCallsTodayHint => 'You\'re all caught up.';

  @override
  String todayPendingCount(int count) {
    return '$count calls pending';
  }

  @override
  String get offlineBanner => 'You\'re offline. You\'re still signed in.';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodCustom => 'Custom';

  @override
  String dateRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get kpiTotalLeads => 'Total leads';

  @override
  String get kpiSiteVisits => 'Site visits';

  @override
  String get kpiCallsLogged => 'Calls logged';

  @override
  String get kpiOverdue => 'Overdue follow-ups';

  @override
  String get kpiUnavailable => 'Not available';

  @override
  String get chartFunnel => 'Lead funnel';

  @override
  String get chartSource => 'By source';

  @override
  String get chartDistrict => 'By district';

  @override
  String get chartOther => 'Other';

  @override
  String get chartNotSet => 'Not set';

  @override
  String get chartNoData => 'No data for this period';

  @override
  String get chartUnavailable => 'Not available on this server';

  @override
  String barValue(int count, int percent) {
    return '$count ($percent%)';
  }

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String filterSourceChip(String value) {
    return 'Source: $value';
  }

  @override
  String filterDistrictChip(String value) {
    return 'District: $value';
  }

  @override
  String get clearFilter => 'Remove filter';

  @override
  String get errorInsecureUrl => 'Enter a secure https:// address';

  @override
  String get blockScreenshots => 'Block screenshots on lead details';

  @override
  String get blockScreenshotsHint =>
      'Hides customer details from screenshots and screen recording';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off';

  @override
  String get openSettings => 'Settings';

  @override
  String get channelNewLeads => 'New leads';

  @override
  String get channelNewLeadsDescription => 'Alerts when a new lead arrives';

  @override
  String get notificationsOffTitle => 'Notifications are off';

  @override
  String get notificationsOffBody =>
      'Turn them on to hear about new leads right away.';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint => 'Ask for a PIN when the app opens';

  @override
  String get useBiometric => 'Unlock with fingerprint';

  @override
  String get useBiometricHint => 'Use fingerprint or face instead of the PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get change => 'Change';

  @override
  String createPinTitle(int length) {
    return 'Set a $length-digit PIN';
  }

  @override
  String get confirmPinTitle => 'Enter the PIN again';

  @override
  String get pinMismatch => 'The PINs did not match. Set it again.';

  @override
  String get enterCurrentPin => 'Enter your current PIN';

  @override
  String get unlockTitle => 'Enter your PIN to unlock';

  @override
  String wrongPin(int count) {
    return 'Wrong PIN. $count tries left';
  }

  @override
  String pinBlocked(int seconds) {
    return 'Too many wrong tries. Try again in $seconds s';
  }

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinBody =>
      'You will be logged out. Log in again with your password, then set a new PIN.';

  @override
  String get cancel => 'Cancel';

  @override
  String get biometricPromptTitle => 'Unlock HI Tech CRM';

  @override
  String get biometricPromptReason => 'Confirm it\'s you';

  @override
  String get biometricButton => 'Use fingerprint';

  @override
  String get biometricLockedOut =>
      'Fingerprint is locked for now. Use your PIN.';

  @override
  String get biometricNotAvailable => 'Fingerprint is not set up on this phone';

  @override
  String get biometricFailed => 'Fingerprint not recognised';

  @override
  String get deleteDigit => 'Delete';

  @override
  String pinDigitsEntered(int count, int total) {
    return '$count of $total digits';
  }

  @override
  String get appLockOn => 'App lock is on';

  @override
  String get pinChanged => 'PIN changed';
}
