# App

[![License: MIT][license_badge]][license_link]

---

# 🚀 Flutter Starter Template

Welcome to the **Flutter Starter Template**! This project is designed to
kickstart your Flutter apps with best practices and built-in support for
**Riverpod**, **Supabase**, and **go_router**. Whether you're building for
**iOS**, **Android**, **Web**, **Windows**, **Linux**, or **MacOS**, this
template has you covered. Let's dive in! 😄

## 🛠 Getting Started

This template supports three flavors:

- **Development**
- **Staging**
- **Production**

To run the desired flavor, either use the launch configuration in VSCode/Android
Studio or execute the following commands:

```bash
# Development
$ flutter run --flavor development --target lib/main_development.dart

# Staging
$ flutter run --flavor staging --target lib/main_staging.dart

# Production
$ flutter run --flavor production --target lib/main_production.dart
```

> **Note**: If you're using packages like `flutter_iconpicker`, add the argument
> `--no-tree-shake-icons` after generating the icon pack.

### Platform Support

This project is enabled for **iOS**, **Android**, **Web**, **Windows**,
**Linux**, and **MacOS**. However, flavors are currently supported only on
**iOS**, **Android**, and **MacOS**.

## 🌐 Working with Translations

We rely on [flutter_localizations][flutter_localizations_link] and follow the
[official internationalization guide for Flutter][internationalization_link].
For a smooth workflow, we use the **L10nization** package developed by
_lsaudon_.

### Adding Translations

To add translations:

1. Select the string in your code.
2. Use the "Extract value to ARB files" action.

Use `context.l10n` or `Approuter.l10n` to access the generated translations.

For each supported locale, add a new ARB file in `lib/l10n/arb`.

Update the `CFBundleLocalizations` array in the `Info.plist` at
`ios/Runner/Info.plist` to include the new locale.

```bash
# Generate localization files
flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## 🎁 Features

This template comes with several inbuilt features:

- Internet connectivity checker
- Environment setup in Flutter & native flavor setup
- Facebook App Events
- Firebase Analytics & Crashlytics
- IPInfo (for country-specific UX like phone number initial code, currency,
  etc.)
- Locale setup
- Platform-dependent PDF/printing setup
- Router config
- Shared Preferences config
- Supabase integration
- Theming setup
- DateTime utils
- Custom extensions
- Responsive layout widget (for adaptive UI)
- Force update feature

## 🔥 Firebase Configuration

This project is already set up for development and production Firebase
configurations.

### Android

Copy the `google_services.json` file to the respective flavor folder:

- For development: `app/src/development`
- For staging: `app/src/staging`
- For production: `app/src/production`

### iOS

Copy `GoogleService-Info.plist` to `ios/Runner/${flavor}`. A script will handle
the rest.

### Web

No additional configuration is required.

### Deploying Web Builds

For deploying to different environments, you can build to separate folders:

```bash
flutter build web -t lib/main_development.dart --no-tree-shake-icons -o 'build/web/development'
firebase deploy -P dev --only hosting:dev

flutter build web -t lib/main_production.dart --no-tree-shake-icons -o 'build/web/production'
firebase deploy -P prod --only hosting:prod
```

Make sure to update `firebase.json`, `.firebaserc`, and add the respective
`google_services.json` and `GoogleService-Info.plist` for Firebase
Crashlytics/Analytics to work properly.

## 🌐 Deeplinking

Deeplinking has already been configured:

- `web/.well-known/app.html` can navigate to respective store pages.
- `web/.well-known/apple-app-site-association` and
  `web/.well-known/assetlinks.json` are needed for iOS and Android deeplinking,
  respectively.
- `web/example.upgrader.xml` is the upgrader config file to enforce mandatory or
  optional updates.

## 📦 Freezed for Model Class Generation

To generate model classes, use:

```bash
dart run build_runner build -d  # -d deletes conflicts
```

> **Warning**: Please avoid using `flutter_launcher_icons`. For high-quality
> icons, follow the respective platform documentation.

- [Android Icon Design](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [iOS Icon Design](https://developer.apple.com/design/human-interface-guidelines/app-icons)

## 🔍 Linting and Analysis

Please try to keep lint warnings and analysis issues to a minimum. 🙏

## 🚀 Hancod Tools

At **Hancod**, we've built a VSCode extension to make your life easier! 🎉

- **Name**: Hancod Riverpod Generator
- **Id**: Hancod.hancod-rivepod
- **Description**: Generate Flutter Riverpod boilerplate code for features
- **Version**: 0.0.1
- **Publisher**: Hancod

### Features

- Automatic directory creation
- Boilerplate code generation for:
  - Repositories
  - Models
  - State Management
  - Notifiers
  - Screens

Right-click on the features folder to create a new module, directory, or
boilerplate code.

## 📦 Hancod Theme Package

We've also created a Flutter package for rapid development of components like
buttons, forms, themes, etc.

### How to Use

1. Create a separate branch for your specific project.
2. Customize it for your needs.
3. Add the package to your dependencies:

```yaml
dependencies:
  hancod_theme:
    git:
      url: https://github.com/Hancod-Digital/hancod_theme.git
      ref: your-project-branch
```

For more information, check the package's
[README.md](https://github.com/alfas-hancod/hancod_theme).

---

This template is designed to save you time and effort, so you can focus on what
matters most—building amazing apps! Happy coding! 🎉

[flutter_localizations_link]: https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html
[internationalization_link]: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

---
