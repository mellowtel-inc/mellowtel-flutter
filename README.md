# Mellowtel

`Mellowtel` is an open-source, consensual, transparent monetization engine for Flutter Apps.

## Usage

With Mellowtel's Open-Source library, your users can share a fraction of their unused internet by using a transparent opt-in/out mechanism. Trusted partners — from startups to 501(c)(3) non profits — access the internet through the network and you get a share of the revenue (1000 users —> around $50 MRR)

## Installation

Add `mellowtel` to your `pubspec.yaml`:

```yaml
dependencies:
  mellowtel:
    git:
      url: <provided in email>
```

Run `flutter pub get` to install the package.

When running on macos, please [configure the macOS App Sandbox](https://inappwebview.dev/docs/intro#setup-macos).

## Usage

### 1. Initialize `Mellowtel`

Start by creating an instance of `Mellowtel` with your unique node ID and details for the user consent popup. 

```dart
import 'package:mellowtel/mellowtel.dart';

final Mellowtel mellowtel = Mellowtel(
    "123",
    appName: 'King Kong',
    appIcon: 'asset/logo.png',
    incentive:
        'Earn 500 coins in Sling Kong',
    yesText: 'FREE Coins!',
  );
```

### 2. Start the Scraping Process

Use the `start()` method to initiate the scraping process.

```dart
await mellowtel.start(
      context, 
      showDefaultConsentDialog: true,
      onOptIn: () async {
        // Handle enabling services when consent is provided.
      }, 
      onOptOut: () async {
        // Handle disabling services if consent is denied.
  });
```

This will open up a one-time consent popup for the user to accept.

<img src = 'assets/consent-popup.png' width = 300px></img>

Later, you may also provide an option for user to update their consent.

```dart
await mellowtel.showConsentSettingsPage(
    context,
    onOptIn: () async {
      // Handle enabling services when consent is provided.
    }, 
    onOptOut: () async {
      // Handle disabling services if consent is denied.
  });
```

### 3. Stop the Scraping Process

To terminate the scraping process, call the `stop()` method.

```dart
await mellowtel.stop();
```



## Platform Support

This package supports iOS, macos and windows platforms. Android and web are not supported.