import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// App name shown on login and in the app bar
  ///
  /// In ta, this message translates to:
  /// **'HI Tech CRM'**
  String get appName;

  /// Subtitle under the app name on the login screen
  ///
  /// In ta, this message translates to:
  /// **'கிணறு ஒப்பந்ததாரர்'**
  String get appSubtitle;

  /// Label for the Frappe server URL field
  ///
  /// In ta, this message translates to:
  /// **'சர்வர் URL'**
  String get serverUrl;

  /// Example value shown inside the empty server URL field
  ///
  /// In ta, this message translates to:
  /// **'https://crm.example.com'**
  String get serverUrlHint;

  /// Label for the email / username field
  ///
  /// In ta, this message translates to:
  /// **'மின்னஞ்சல் / பயனர் பெயர்'**
  String get username;

  /// Label for the password field
  ///
  /// In ta, this message translates to:
  /// **'கடவுச்சொல்'**
  String get password;

  /// Tooltip on the eye icon when the password is hidden
  ///
  /// In ta, this message translates to:
  /// **'காட்டு'**
  String get showPassword;

  /// Tooltip on the eye icon when the password is visible
  ///
  /// In ta, this message translates to:
  /// **'மறை'**
  String get hidePassword;

  /// Login button text
  ///
  /// In ta, this message translates to:
  /// **'உள்நுழை'**
  String get loginButton;

  /// Validation error for an empty required field
  ///
  /// In ta, this message translates to:
  /// **'இது தேவை'**
  String get fieldRequired;

  /// Ping to the server failed or did not return pong
  ///
  /// In ta, this message translates to:
  /// **'சர்வரை அணுக முடியவில்லை. URL-ஐ சரிபார்க்கவும்.'**
  String get errorServerUnreachable;

  /// Login returned 401
  ///
  /// In ta, this message translates to:
  /// **'தவறான பயனர் பெயர் அல்லது கடவுச்சொல்'**
  String get errorWrongPassword;

  /// Request timed out or there is no network
  ///
  /// In ta, this message translates to:
  /// **'இணைய இணைப்பை சரிபார்க்கவும்'**
  String get errorNoInternet;

  /// Any other login failure
  ///
  /// In ta, this message translates to:
  /// **'உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.'**
  String get errorUnknown;

  /// Greeting on the home screen
  ///
  /// In ta, this message translates to:
  /// **'வணக்கம், {name}'**
  String welcomeUser(String name);

  /// Tooltip on the logout icon
  ///
  /// In ta, this message translates to:
  /// **'வெளியேறு'**
  String get logout;

  /// Title of the logout confirmation dialog
  ///
  /// In ta, this message translates to:
  /// **'வெளியேறவா?'**
  String get logoutConfirm;

  /// Confirm button
  ///
  /// In ta, this message translates to:
  /// **'ஆம்'**
  String get yes;

  /// Cancel button
  ///
  /// In ta, this message translates to:
  /// **'இல்லை'**
  String get no;

  /// Tamil option in the language toggle; always written in Tamil
  ///
  /// In ta, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// English option in the language toggle; always 'EN'
  ///
  /// In ta, this message translates to:
  /// **'EN'**
  String get languageEnglish;

  /// Heading of the login form
  ///
  /// In ta, this message translates to:
  /// **'உள்நுழைக'**
  String get loginTitle;

  /// Muted line under the login heading
  ///
  /// In ta, this message translates to:
  /// **'உங்கள் கணக்கில் உள்நுழையவும்'**
  String get loginHint;

  /// One-line tagline on the wide-screen brand panel
  ///
  /// In ta, this message translates to:
  /// **'கிணறு பணிகள், வாடிக்கையாளர்கள், கட்டணங்கள் — ஒரே இடத்தில்'**
  String get brandTagline;

  /// Collapsed server row when a URL is saved
  ///
  /// In ta, this message translates to:
  /// **'சர்வர்: {host}'**
  String serverSummary(String host);

  /// Action on the collapsed server row that reveals the URL field
  ///
  /// In ta, this message translates to:
  /// **'மாற்று'**
  String get changeServer;

  /// Footer text before the app version is known
  ///
  /// In ta, this message translates to:
  /// **'© HI Tech Open Well Contractor'**
  String get footerCopyright;

  /// Footer with app version
  ///
  /// In ta, this message translates to:
  /// **'© HI Tech Open Well Contractor · பதிப்பு {version}'**
  String footerWithVersion(String version);

  /// Bottom nav: today's work
  ///
  /// In ta, this message translates to:
  /// **'இன்று'**
  String get tabToday;

  /// Bottom nav: leads list
  ///
  /// In ta, this message translates to:
  /// **'லீட்கள்'**
  String get tabLeads;

  /// Bottom nav: site visits
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வு'**
  String get tabVisits;

  /// Title of the create site visit screen
  ///
  /// In ta, this message translates to:
  /// **'புதிய இட ஆய்வு'**
  String get visitNew;

  /// Action to create a site visit
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வு சேர்'**
  String get visitAdd;

  /// Empty site visit list title
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வுகள் இல்லை'**
  String get visitEmptyTitle;

  /// Empty site visit list explanation
  ///
  /// In ta, this message translates to:
  /// **'புதிய இட ஆய்வை திட்டமிட்டால் இங்கே காணலாம்.'**
  String get visitEmptyHint;

  /// Planned status label
  ///
  /// In ta, this message translates to:
  /// **'திட்டமிடப்பட்டது'**
  String get visitPlanned;

  /// Completed status label
  ///
  /// In ta, this message translates to:
  /// **'முடிந்தது'**
  String get visitCompleted;

  /// Cancelled status label
  ///
  /// In ta, this message translates to:
  /// **'ரத்து செய்யப்பட்டது'**
  String get visitCancelled;

  /// Visit without a date
  ///
  /// In ta, this message translates to:
  /// **'தேதி அமைக்கப்படவில்லை'**
  String get visitDateUnset;

  /// Visit date and time label
  ///
  /// In ta, this message translates to:
  /// **'ஆய்வு தேதி மற்றும் நேரம்'**
  String get visitDateTime;

  /// Confirmation after updating a visit status
  ///
  /// In ta, this message translates to:
  /// **'நிலை {status} என புதுப்பிக்கப்பட்டது'**
  String visitStatusUpdated(String status);

  /// Failure to update visit status
  ///
  /// In ta, this message translates to:
  /// **'நிலையை புதுப்பிக்க முடியவில்லை'**
  String get visitStatusFailed;

  /// Section heading for well details
  ///
  /// In ta, this message translates to:
  /// **'கிணறு விவரங்கள்'**
  String get visitWellDetails;

  /// Well diameter in feet
  ///
  /// In ta, this message translates to:
  /// **'விட்டம் (அடி)'**
  String get visitDiameterFt;

  /// Expected well depth in feet
  ///
  /// In ta, this message translates to:
  /// **'எதிர்பார்க்கும் ஆழம் (அடி)'**
  String get visitExpectedDepthFt;

  /// Depth where rock starts, in feet
  ///
  /// In ta, this message translates to:
  /// **'பாறை தொடங்கும் ஆழம் (அடி)'**
  String get visitRockFromFt;

  /// Well depth input in feet
  ///
  /// In ta, this message translates to:
  /// **'ஆழம் (அடி)'**
  String get visitDepthFt;

  /// Soil type field
  ///
  /// In ta, this message translates to:
  /// **'மண் வகை'**
  String get visitSoilType;

  /// Red Soil value
  ///
  /// In ta, this message translates to:
  /// **'செம்மண்'**
  String get visitSoilRed;

  /// Black Soil value
  ///
  /// In ta, this message translates to:
  /// **'கரிசல் மண்'**
  String get visitSoilBlack;

  /// Sandy Soil value
  ///
  /// In ta, this message translates to:
  /// **'மணல் மண்'**
  String get visitSoilSandy;

  /// Rock soil type value
  ///
  /// In ta, this message translates to:
  /// **'பாறை'**
  String get visitSoilRock;

  /// Missing optional well detail
  ///
  /// In ta, this message translates to:
  /// **'குறிப்பிடப்படவில்லை'**
  String get visitNotSpecified;

  /// GPS location section
  ///
  /// In ta, this message translates to:
  /// **'GPS இடம்'**
  String get visitLocationGps;

  /// GPS coordinates
  ///
  /// In ta, this message translates to:
  /// **'அட்சரேகை: {lat}, தீர்க்கரேகை: {lon}'**
  String visitCoordinates(String lat, String lon);

  /// Open coordinates in Google Maps
  ///
  /// In ta, this message translates to:
  /// **'Google Maps-இல் திற'**
  String get visitOpenMaps;

  /// Notes section and field
  ///
  /// In ta, this message translates to:
  /// **'குறிப்புகள்'**
  String get visitNotes;

  /// Failure to create a site visit
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வை உருவாக்க முடியவில்லை'**
  String get visitCreateFailed;

  /// Required client or lead name
  ///
  /// In ta, this message translates to:
  /// **'வாடிக்கையாளர் / லீட் பெயர் *'**
  String get visitClientLeadName;

  /// Search field for the required linked CRM Lead
  ///
  /// In ta, this message translates to:
  /// **'லீட்டைத் தேர்ந்தெடுக்கவும் *'**
  String get visitSelectLead;

  /// Validation when no linked CRM Lead was selected
  ///
  /// In ta, this message translates to:
  /// **'தேடல் முடிவிலிருந்து ஒரு லீட்டைத் தேர்ந்தெடுக்கவும்'**
  String get visitLeadRequired;

  /// Required mobile number
  ///
  /// In ta, this message translates to:
  /// **'கைபேசி எண் *'**
  String get visitMobileRequired;

  /// Save site visit action
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வை சேமி'**
  String get visitSave;

  /// Bottom nav: profile
  ///
  /// In ta, this message translates to:
  /// **'சுயவிவரம்'**
  String get tabProfile;

  /// Placeholder for features not built yet
  ///
  /// In ta, this message translates to:
  /// **'விரைவில் வருகிறது'**
  String get comingSoon;

  /// Line under 'Coming soon'
  ///
  /// In ta, this message translates to:
  /// **'இந்தப் பகுதி அடுத்த பதிப்பில் வரும்.'**
  String get comingSoonHint;

  /// Leads screen app bar title
  ///
  /// In ta, this message translates to:
  /// **'லீட்கள்'**
  String get leadsTitle;

  /// Tooltip on the search icon
  ///
  /// In ta, this message translates to:
  /// **'தேடு'**
  String get search;

  /// Tooltip on the button that closes the search field
  ///
  /// In ta, this message translates to:
  /// **'தேடலை மூடு'**
  String get closeSearch;

  /// Hint inside the leads search field
  ///
  /// In ta, this message translates to:
  /// **'பெயர் அல்லது மொபைல் எண்'**
  String get searchLeadsHint;

  /// Status filter chip that shows every lead
  ///
  /// In ta, this message translates to:
  /// **'அனைத்தும்'**
  String get filterAll;

  /// Empty state title
  ///
  /// In ta, this message translates to:
  /// **'லீட் எதுவும் இல்லை'**
  String get noLeads;

  /// Empty state hint
  ///
  /// In ta, this message translates to:
  /// **'வேறு வடிகட்டி அல்லது தேடலை முயற்சிக்கவும்.'**
  String get noLeadsHint;

  /// Retry button on error states
  ///
  /// In ta, this message translates to:
  /// **'மீண்டும் முயற்சி'**
  String get retry;

  /// Button shown when the session has expired
  ///
  /// In ta, this message translates to:
  /// **'மீண்டும் உள்நுழை'**
  String get loginAgain;

  /// 401/403 from the server
  ///
  /// In ta, this message translates to:
  /// **'அமர்வு காலாவதியானது அல்லது அனுமதி இல்லை. மீண்டும் உள்நுழையவும்.'**
  String get errorUnauthorized;

  /// 5xx or unexpected server response
  ///
  /// In ta, this message translates to:
  /// **'சர்வரில் பிழை. சிறிது நேரம் கழித்து முயற்சிக்கவும்.'**
  String get errorServer;

  /// Any other data error
  ///
  /// In ta, this message translates to:
  /// **'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.'**
  String get errorGeneric;

  /// Footer when loading the next page failed
  ///
  /// In ta, this message translates to:
  /// **'மேலும் ஏற்ற முடியவில்லை'**
  String get loadMoreFailed;

  /// Tooltip on the add-lead button
  ///
  /// In ta, this message translates to:
  /// **'புதிய லீட்'**
  String get newLead;

  /// Heading for the new lead form
  ///
  /// In ta, this message translates to:
  /// **'லீட் விவரங்கள்'**
  String get newLeadDetails;

  /// Confirmation after a lead is created
  ///
  /// In ta, this message translates to:
  /// **'லீட் உருவாக்கப்பட்டது'**
  String get leadCreated;

  /// Required first name field for a new lead
  ///
  /// In ta, this message translates to:
  /// **'முதல் பெயர் *'**
  String get firstName;

  /// Optional last name field
  ///
  /// In ta, this message translates to:
  /// **'கடைசி பெயர்'**
  String get lastName;

  /// Optional mobile number field
  ///
  /// In ta, this message translates to:
  /// **'கைபேசி எண்'**
  String get mobileNumber;

  /// Optional email field
  ///
  /// In ta, this message translates to:
  /// **'மின்னஞ்சல் முகவரி'**
  String get emailAddress;

  /// Village field
  ///
  /// In ta, this message translates to:
  /// **'கிராமம்'**
  String get village;

  /// District field
  ///
  /// In ta, this message translates to:
  /// **'மாவட்டம்'**
  String get district;

  /// Work type dropdown label
  ///
  /// In ta, this message translates to:
  /// **'வேலை வகை'**
  String get workType;

  /// New Well option
  ///
  /// In ta, this message translates to:
  /// **'புதிய கிணறு'**
  String get workTypeNewWell;

  /// Well Deepening option
  ///
  /// In ta, this message translates to:
  /// **'கிணறு ஆழப்படுத்தல்'**
  String get workTypeDeepening;

  /// Wall Construction option
  ///
  /// In ta, this message translates to:
  /// **'சுவர் கட்டுமானம்'**
  String get workTypeWall;

  /// Desilting option
  ///
  /// In ta, this message translates to:
  /// **'தூர்வாருதல்'**
  String get workTypeDesilting;

  /// Water Survey option
  ///
  /// In ta, this message translates to:
  /// **'நீர் ஆய்வு'**
  String get workTypeSurvey;

  /// Validation for an invalid phone number
  ///
  /// In ta, this message translates to:
  /// **'சரியான தொலைபேசி எண்ணை உள்ளிடவும்'**
  String get invalidPhone;

  /// Validation for an invalid email address
  ///
  /// In ta, this message translates to:
  /// **'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்'**
  String get invalidEmail;

  /// Shown when a lead has no name
  ///
  /// In ta, this message translates to:
  /// **'பெயரில்லா லீட்'**
  String get unnamedLead;

  /// Lead detail placeholder
  ///
  /// In ta, this message translates to:
  /// **'முழு விவரங்கள் அடுத்த பதிப்பில் வரும்.'**
  String get leadDetailComingSoon;

  /// Relative time under 1 minute
  ///
  /// In ta, this message translates to:
  /// **'இப்போது'**
  String get timeJustNow;

  /// Relative time in minutes
  ///
  /// In ta, this message translates to:
  /// **'{count} நிமிடம் முன்'**
  String timeMinutesAgo(int count);

  /// Relative time in hours
  ///
  /// In ta, this message translates to:
  /// **'{count} மணி நேரம் முன்'**
  String timeHoursAgo(int count);

  /// Relative time in days
  ///
  /// In ta, this message translates to:
  /// **'{count} நாள் முன்'**
  String timeDaysAgo(int count);

  /// Default Frappe CRM lead status 'New'
  ///
  /// In ta, this message translates to:
  /// **'புதியது'**
  String get statusNew;

  /// Default lead status 'Contacted'
  ///
  /// In ta, this message translates to:
  /// **'தொடர்பு கொண்டது'**
  String get statusContacted;

  /// Default lead status 'Nurture'
  ///
  /// In ta, this message translates to:
  /// **'பின்தொடர்தல்'**
  String get statusNurture;

  /// Default lead status 'Qualified'
  ///
  /// In ta, this message translates to:
  /// **'தகுதியானது'**
  String get statusQualified;

  /// Default lead status 'Unqualified'
  ///
  /// In ta, this message translates to:
  /// **'தகுதியற்றது'**
  String get statusUnqualified;

  /// Default lead status 'Junk'
  ///
  /// In ta, this message translates to:
  /// **'பயனற்றது'**
  String get statusJunk;

  /// Profile row: server URL
  ///
  /// In ta, this message translates to:
  /// **'சர்வர்'**
  String get profileServer;

  /// Profile row: language toggle
  ///
  /// In ta, this message translates to:
  /// **'மொழி'**
  String get profileLanguage;

  /// Profile row: app version
  ///
  /// In ta, this message translates to:
  /// **'பதிப்பு'**
  String get profileVersion;

  /// Button that opens the phone dialer
  ///
  /// In ta, this message translates to:
  /// **'அழை'**
  String get callAction;

  /// Button that opens WhatsApp chat
  ///
  /// In ta, this message translates to:
  /// **'WhatsApp'**
  String get whatsappAction;

  /// url_launcher failed
  ///
  /// In ta, this message translates to:
  /// **'செயலியைத் திறக்க முடியவில்லை'**
  String get couldNotOpenApp;

  /// Section title for status chips on lead detail
  ///
  /// In ta, this message translates to:
  /// **'நிலை'**
  String get leadStatusSection;

  /// Confirm dialog before changing lead status
  ///
  /// In ta, this message translates to:
  /// **'நிலையை \"{status}\" என மாற்றவா?'**
  String changeStatusConfirm(String status);

  /// SnackBar after status change
  ///
  /// In ta, this message translates to:
  /// **'நிலை புதுப்பிக்கப்பட்டது'**
  String get statusUpdated;

  /// Card title for logging a call
  ///
  /// In ta, this message translates to:
  /// **'அழைப்பைப் பதிவு செய்'**
  String get logCallTitle;

  /// Label above outcome chips
  ///
  /// In ta, this message translates to:
  /// **'அழைப்பு முடிவு'**
  String get callOutcome;

  /// Call outcome
  ///
  /// In ta, this message translates to:
  /// **'பேசியாச்சு'**
  String get outcomeTalked;

  /// Call outcome
  ///
  /// In ta, this message translates to:
  /// **'எடுக்கவில்லை'**
  String get outcomeNoAnswer;

  /// Call outcome
  ///
  /// In ta, this message translates to:
  /// **'பிஸி'**
  String get outcomeBusy;

  /// Call outcome
  ///
  /// In ta, this message translates to:
  /// **'தவறான எண்'**
  String get outcomeWrongNumber;

  /// Validation when no outcome is chosen
  ///
  /// In ta, this message translates to:
  /// **'அழைப்பு முடிவைத் தேர்ந்தெடுக்கவும்'**
  String get outcomeRequired;

  /// Label for the call note field
  ///
  /// In ta, this message translates to:
  /// **'குறிப்பு (விருப்பம்)'**
  String get callNoteLabel;

  /// Hint inside the call note field
  ///
  /// In ta, this message translates to:
  /// **'என்ன பேசினீர்கள்?'**
  String get callNoteHint;

  /// Label for the follow-up date/time
  ///
  /// In ta, this message translates to:
  /// **'அடுத்த பின்தொடர்தல்'**
  String get nextFollowUp;

  /// Semantics label of the follow-up picker button
  ///
  /// In ta, this message translates to:
  /// **'தேதி/நேரத்தை மாற்று'**
  String get changeFollowUp;

  /// Shown instead of the date picker for wrong number
  ///
  /// In ta, this message translates to:
  /// **'தவறான எண்ணுக்கு பின்தொடர்தல் உருவாக்கப்படாது.'**
  String get noFollowUpForWrongNumber;

  /// Save button
  ///
  /// In ta, this message translates to:
  /// **'சேமி'**
  String get save;

  /// SnackBar after saving a call
  ///
  /// In ta, this message translates to:
  /// **'சேமிக்கப்பட்டது'**
  String get saved;

  /// Card title for the next open task
  ///
  /// In ta, this message translates to:
  /// **'வரவிருக்கும் பின்தொடர்தல்'**
  String get upcomingFollowUp;

  /// Badge for a task past its due date
  ///
  /// In ta, this message translates to:
  /// **'தாமதம்'**
  String get overdue;

  /// Shown when the lead has no open task
  ///
  /// In ta, this message translates to:
  /// **'திட்டமிட்ட பின்தொடர்தல் இல்லை'**
  String get noUpcomingFollowUp;

  /// Open task without a due date
  ///
  /// In ta, this message translates to:
  /// **'தேதி இல்லை'**
  String get noDueDate;

  /// Section title for notes
  ///
  /// In ta, this message translates to:
  /// **'வரலாறு'**
  String get historyTitle;

  /// Empty notes list
  ///
  /// In ta, this message translates to:
  /// **'இன்னும் குறிப்புகள் இல்லை'**
  String get noNotes;

  /// Localized display of a 'Call: <outcome>' note title
  ///
  /// In ta, this message translates to:
  /// **'அழைப்பு: {outcome}'**
  String callNoteTitle(String outcome);

  /// Localized display of the 'Follow-up call' task title
  ///
  /// In ta, this message translates to:
  /// **'பின்தொடர் அழைப்பு'**
  String get followUpTaskTitle;

  /// Today summary tile: all items
  ///
  /// In ta, this message translates to:
  /// **'மொத்தம்'**
  String get statTotal;

  /// Today summary tile / filter: new leads not yet called
  ///
  /// In ta, this message translates to:
  /// **'புதியவை'**
  String get statNew;

  /// Today filter chip: follow-ups due later today
  ///
  /// In ta, this message translates to:
  /// **'இன்று'**
  String get filterDueToday;

  /// Filter chip label with a count
  ///
  /// In ta, this message translates to:
  /// **'{label} ({count})'**
  String chipWithCount(String label, int count);

  /// Badge on an overdue follow-up
  ///
  /// In ta, this message translates to:
  /// **'{count, plural, =1{1 நாள் தாமதம்} other{{count} நாள் தாமதம்}}'**
  String daysLate(int count);

  /// Badge on a new lead in the Today list
  ///
  /// In ta, this message translates to:
  /// **'புதிய'**
  String get newBadge;

  /// Today empty state
  ///
  /// In ta, this message translates to:
  /// **'இன்று அழைக்க யாரும் இல்லை'**
  String get noCallsToday;

  /// Line under the Today empty state
  ///
  /// In ta, this message translates to:
  /// **'எல்லாம் முடிந்தது!'**
  String get noCallsTodayHint;

  /// Screen-reader label of the Today tab badge
  ///
  /// In ta, this message translates to:
  /// **'{count} அழைப்புகள் நிலுவையில்'**
  String todayPendingCount(int count);

  /// Shown at app start when the server can't be reached but the saved login is kept
  ///
  /// In ta, this message translates to:
  /// **'இணைய இணைப்பு இல்லை. நீங்கள் இன்னும் உள்நுழைந்தே உள்ளீர்கள்.'**
  String get offlineBanner;

  /// Bottom nav + app bar: dashboard
  ///
  /// In ta, this message translates to:
  /// **'டாஷ்போர்டு'**
  String get tabDashboard;

  /// Dashboard period: today
  ///
  /// In ta, this message translates to:
  /// **'இன்று'**
  String get periodToday;

  /// Dashboard period: this week (Mon–Sun)
  ///
  /// In ta, this message translates to:
  /// **'இந்த வாரம்'**
  String get periodWeek;

  /// Dashboard period: this month
  ///
  /// In ta, this message translates to:
  /// **'இந்த மாதம்'**
  String get periodMonth;

  /// Dashboard period: pick a date range
  ///
  /// In ta, this message translates to:
  /// **'தனிப்பயன்'**
  String get periodCustom;

  /// Custom period chip once a range is picked
  ///
  /// In ta, this message translates to:
  /// **'{from} – {to}'**
  String dateRange(String from, String to);

  /// KPI tile
  ///
  /// In ta, this message translates to:
  /// **'மொத்த லீட்கள்'**
  String get kpiTotalLeads;

  /// KPI tile
  ///
  /// In ta, this message translates to:
  /// **'இட ஆய்வுகள்'**
  String get kpiSiteVisits;

  /// KPI tile
  ///
  /// In ta, this message translates to:
  /// **'பதிவான அழைப்புகள்'**
  String get kpiCallsLogged;

  /// KPI tile (red); not limited to the period
  ///
  /// In ta, this message translates to:
  /// **'தாமதமான பின்தொடர்தல்கள்'**
  String get kpiOverdue;

  /// KPI value when the server has no such data
  ///
  /// In ta, this message translates to:
  /// **'கிடைக்கவில்லை'**
  String get kpiUnavailable;

  /// Chart title: leads per status
  ///
  /// In ta, this message translates to:
  /// **'லீட் நிலைகள்'**
  String get chartFunnel;

  /// Chart title: leads per source
  ///
  /// In ta, this message translates to:
  /// **'மூலம் வாரியாக'**
  String get chartSource;

  /// Chart title: leads per district
  ///
  /// In ta, this message translates to:
  /// **'மாவட்டம் வாரியாக'**
  String get chartDistrict;

  /// Bar that sums the remaining districts
  ///
  /// In ta, this message translates to:
  /// **'மற்றவை'**
  String get chartOther;

  /// Bar for leads with an empty value
  ///
  /// In ta, this message translates to:
  /// **'குறிப்பிடப்படவில்லை'**
  String get chartNotSet;

  /// Empty chart
  ///
  /// In ta, this message translates to:
  /// **'இந்தக் காலத்தில் தரவு இல்லை'**
  String get chartNoData;

  /// Chart whose field/doctype is missing on the server
  ///
  /// In ta, this message translates to:
  /// **'இந்தத் தகவல் சர்வரில் இல்லை'**
  String get chartUnavailable;

  /// Value label on a bar
  ///
  /// In ta, this message translates to:
  /// **'{count} ({percent}%)'**
  String barValue(int count, int percent);

  /// Last refresh time at the bottom of the dashboard
  ///
  /// In ta, this message translates to:
  /// **'புதுப்பிக்கப்பட்டது {time}'**
  String updatedAt(String time);

  /// Active source filter chip on Leads
  ///
  /// In ta, this message translates to:
  /// **'மூலம்: {value}'**
  String filterSourceChip(String value);

  /// Active district filter chip on Leads
  ///
  /// In ta, this message translates to:
  /// **'மாவட்டம்: {value}'**
  String filterDistrictChip(String value);

  /// Screen-reader hint on a removable filter chip
  ///
  /// In ta, this message translates to:
  /// **'வடிகட்டியை நீக்கு'**
  String get clearFilter;

  /// Server URL is not https
  ///
  /// In ta, this message translates to:
  /// **'பாதுகாப்பான https:// முகவரியை உள்ளிடவும்'**
  String get errorInsecureUrl;

  /// Profile setting (Android FLAG_SECURE)
  ///
  /// In ta, this message translates to:
  /// **'விவரத் திரையில் ஸ்கிரீன்ஷாட்டைத் தடு'**
  String get blockScreenshots;

  /// Explanation under the screenshot setting
  ///
  /// In ta, this message translates to:
  /// **'வாடிக்கையாளர் விவரங்களை ஸ்கிரீன்ஷாட் மற்றும் திரைப் பதிவிலிருந்து பாதுகாக்கும்'**
  String get blockScreenshotsHint;

  /// Profile row title
  ///
  /// In ta, this message translates to:
  /// **'அறிவிப்புகள்'**
  String get notifications;

  /// Notification status
  ///
  /// In ta, this message translates to:
  /// **'இயக்கத்தில்'**
  String get notificationsOn;

  /// Notification status
  ///
  /// In ta, this message translates to:
  /// **'முடக்கத்தில்'**
  String get notificationsOff;

  /// Button that opens the system notification settings
  ///
  /// In ta, this message translates to:
  /// **'அமைப்புகள்'**
  String get openSettings;

  /// Android notification channel name
  ///
  /// In ta, this message translates to:
  /// **'புதிய லீட்கள்'**
  String get channelNewLeads;

  /// Android notification channel description
  ///
  /// In ta, this message translates to:
  /// **'புதிய லீட் வந்தவுடன் தெரிவிக்கும்'**
  String get channelNewLeadsDescription;

  /// Today info card title when permission was denied
  ///
  /// In ta, this message translates to:
  /// **'அறிவிப்புகள் முடக்கப்பட்டுள்ளன'**
  String get notificationsOffTitle;

  /// Today info card text
  ///
  /// In ta, this message translates to:
  /// **'புதிய லீட்கள் வந்தவுடன் தெரிந்துகொள்ள அறிவிப்புகளை இயக்கவும்.'**
  String get notificationsOffBody;

  /// Today info card button
  ///
  /// In ta, this message translates to:
  /// **'அறிவிப்புகளை இயக்கு'**
  String get enableNotifications;

  /// Close button on an info card
  ///
  /// In ta, this message translates to:
  /// **'மூடு'**
  String get dismiss;

  /// Profile setting: lock the app with a PIN
  ///
  /// In ta, this message translates to:
  /// **'செயலி பூட்டு'**
  String get appLock;

  /// Explanation under the app lock setting
  ///
  /// In ta, this message translates to:
  /// **'செயலியைத் திறக்கும்போது PIN கேட்கும்'**
  String get appLockHint;

  /// Profile setting: fingerprint / face unlock
  ///
  /// In ta, this message translates to:
  /// **'கைரேகை மூலம் திற'**
  String get useBiometric;

  /// Explanation under the fingerprint setting
  ///
  /// In ta, this message translates to:
  /// **'PIN-க்குப் பதிலாக கைரேகை அல்லது முகத்தைப் பயன்படுத்தலாம்'**
  String get useBiometricHint;

  /// Profile row button
  ///
  /// In ta, this message translates to:
  /// **'PIN-ஐ மாற்று'**
  String get changePin;

  /// Short button that opens the change-PIN screen
  ///
  /// In ta, this message translates to:
  /// **'மாற்று'**
  String get change;

  /// PIN setup step 1
  ///
  /// In ta, this message translates to:
  /// **'{length} இலக்க PIN-ஐ அமைக்கவும்'**
  String createPinTitle(int length);

  /// PIN setup step 2
  ///
  /// In ta, this message translates to:
  /// **'PIN-ஐ மீண்டும் உள்ளிடவும்'**
  String get confirmPinTitle;

  /// PIN setup error
  ///
  /// In ta, this message translates to:
  /// **'PIN பொருந்தவில்லை. மீண்டும் அமைக்கவும்.'**
  String get pinMismatch;

  /// Before turning off or changing the PIN
  ///
  /// In ta, this message translates to:
  /// **'தற்போதைய PIN-ஐ உள்ளிடவும்'**
  String get enterCurrentPin;

  /// Lock screen title
  ///
  /// In ta, this message translates to:
  /// **'திறக்க PIN-ஐ உள்ளிடவும்'**
  String get unlockTitle;

  /// Lock screen error
  ///
  /// In ta, this message translates to:
  /// **'தவறான PIN. இன்னும் {count} முறை முயலலாம்'**
  String wrongPin(int count);

  /// Lock screen wait message
  ///
  /// In ta, this message translates to:
  /// **'பல முறை தவறு. {seconds} வினாடிகளில் மீண்டும் முயலவும்'**
  String pinBlocked(int seconds);

  /// Lock screen link
  ///
  /// In ta, this message translates to:
  /// **'PIN மறந்துவிட்டதா?'**
  String get forgotPin;

  /// Forgot-PIN confirmation text
  ///
  /// In ta, this message translates to:
  /// **'நீங்கள் வெளியேற்றப்படுவீர்கள். உங்கள் கடவுச்சொல்லுடன் மீண்டும் உள்நுழைந்து புதிய PIN-ஐ அமைக்கலாம்.'**
  String get forgotPinBody;

  /// Cancel button
  ///
  /// In ta, this message translates to:
  /// **'ரத்து செய்'**
  String get cancel;

  /// System fingerprint prompt title
  ///
  /// In ta, this message translates to:
  /// **'HI Tech CRM-ஐத் திற'**
  String get biometricPromptTitle;

  /// System fingerprint prompt text
  ///
  /// In ta, this message translates to:
  /// **'இது நீங்கள்தான் என உறுதிசெய்யவும்'**
  String get biometricPromptReason;

  /// Lock screen fingerprint button
  ///
  /// In ta, this message translates to:
  /// **'கைரேகையைப் பயன்படுத்து'**
  String get biometricButton;

  /// Too many fingerprint tries
  ///
  /// In ta, this message translates to:
  /// **'கைரேகை தற்காலிகமாகப் பூட்டப்பட்டது. PIN-ஐப் பயன்படுத்தவும்.'**
  String get biometricLockedOut;

  /// Fingerprint unavailable
  ///
  /// In ta, this message translates to:
  /// **'இந்த போனில் கைரேகை அமைக்கப்படவில்லை'**
  String get biometricNotAvailable;

  /// Fingerprint check failed
  ///
  /// In ta, this message translates to:
  /// **'கைரேகை உறுதிசெய்யப்படவில்லை'**
  String get biometricFailed;

  /// Screen-reader label of the keypad delete key
  ///
  /// In ta, this message translates to:
  /// **'நீக்கு'**
  String get deleteDigit;

  /// Screen-reader label of the PIN dots
  ///
  /// In ta, this message translates to:
  /// **'{total} இல் {count} இலக்கங்கள்'**
  String pinDigitsEntered(int count, int total);

  /// Snackbar after setting a PIN
  ///
  /// In ta, this message translates to:
  /// **'செயலி பூட்டு இயக்கப்பட்டது'**
  String get appLockOn;

  /// Snackbar after changing the PIN
  ///
  /// In ta, this message translates to:
  /// **'PIN மாற்றப்பட்டது'**
  String get pinChanged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
