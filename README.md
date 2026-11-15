# HI Tech CRM mobile

Flutter client for the HI Tech Frappe CRM backend. The current repository builds an Android app; it does not contain an iOS project. The app supports Tamil and English, including the Visits flow.

## Development

Use Flutter 3.47.8 (Dart 3.13.7) and JDK 17. The Android project uses Gradle 9.3.1. The Gradle wrapper scripts and JAR are part of this repository so a fresh checkout can build.

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

The Android Firebase configuration is in `android/app/google-services.json`. Provision the matching Firebase project and the Frappe backend's push credentials before testing notifications. A production server URL must use HTTPS. HTTP is accepted only for localhost or the Android emulator in debug builds.

## Android release

1. Choose and verify the final Android application ID, Firebase Android app registration, and Play Console listing before publishing. Changing the application ID after release requires a new store listing.
2. Create an upload keystore outside the repository. Copy `android/key.properties.example` to `android/key.properties` and fill in the absolute keystore path, passwords, and alias. Both the properties file and keystore are ignored by Git. Keep secure backups of the upload key.
3. Increment the `version` in `pubspec.yaml` for each upload. Build an Android App Bundle:

```sh
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

4. Retain the matching `build/symbols` privately for crash symbolication. Verify the AAB signature and install a release build on a physical Android device before a staged Play rollout.

The release build fails if `android/key.properties` is missing. Never publish a debug APK.

## Release gate

Automated checks cover static analysis, unit and widget tests, and an Android debug build. A production launch additionally requires:

- A signed **release** AAB built and tested with the actual upload key. This checkout has no release key, so that check cannot be completed here.
- End-to-end testing against the intended production Frappe site with real user permissions: login, session expiry, lead list/detail, call follow-up, Visits, dashboard, logout, and account switching.
- Push testing on physical devices in foreground, background, and terminated states, including token registration/unregistration and permission denial.
- Offline and reconnect testing for each write flow. There is no durable offline write queue; the current app needs a connection to save changes.
- Store assets, privacy policy, data safety declarations, crash monitoring, and a staged rollout with a rollback plan.

Treat the app as a release candidate until these checks pass.
