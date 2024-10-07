# Mellowtel

`Mellowtel` is an open-source, consensual, transparent monetization engine for Flutter Apps.

## Usage

With Mellowtel's Open-Source library, your users can share a fraction of their unused internet by using a transparent opt-in/out mechanism. Trusted partners — from startups to 501(c)(3) non profits — access the internet through the network and you get a share of the revenue (1000 users —> around $50 MRR)

You can [signup](https://www.mellowtel.dev/flutter/) for mellowtel to join as a developer.

## Installation

Add `mellowtel` to your pubspec:

```bash
flutter pub add mellowtel
```

When running on macos, please [configure the macOS App Sandbox](https://inappwebview.dev/docs/intro#setup-macos) by providing only network permissions. (Skip the Hardware permissions)

## Usage

### 1. Initialize `Mellowtel`

Start by creating an instance of `Mellowtel` with your unique configuration key and details for the user consent popup. 

```dart
import 'package:mellowtel/mellowtel.dart';

final Mellowtel mellowtel = Mellowtel(
    "123", // your designated configuration key as received in email
    appName: 'King Kong',
    appIcon: 'asset/logo.png',
    incentive:
        'Earn 500 coins in Sling Kong',
    yesText: 'FREE Coins!',
  );
```

### 2. Start the Scraping Process

Use the `start()` method to signal mellowtel to start operating.

```dart
await mellowtel.start(
      context, // [BuildContext] to show the consent popup.
      onOptIn: () async {
        // Handle enabling services when consent is provided.
      }, 
      onOptOut: () async {
        // Handle disabling services if consent is denied.
      },
      showConsentDialog: true
    );
```

This will open up a one-time consent popup for the user to accept.

<img src = 'https://raw.githubusercontent.com/mellowtel-inc/mellowtel-flutter/main/assets/consent-popup.png' width = 300px></img>

> You can change `showConsentDialog` param to false to ask for consent manually or in a differnt page after a successful user interaction.

### 3. Consent Settings Page (Optional)

Mellowtel ensures full control and privacy for your users. Your users can change their consent at any time from the Consent Settings Page. You may provide it as an option within the settings page of your app.

```dart
await mellowtel.showConsentSettingsPage(
    context,
    onOptIn: () async {
      // Handle enabling services when consent is provided.
    }, 
    onOptOut: () async {
      // Handle disabling services if consent is denied.
    },
  );
```

<img src = 'https://raw.githubusercontent.com/mellowtel-inc/mellowtel-flutter/main/assets/settings-popup.png' width = 300px></img>




### 4. Befrore you deploy 

To ensure that mellowtel is succesfully operating, test your app with `showDebugLogs` set to true.


```dart
import 'package:mellowtel/mellowtel.dart';

final Mellowtel mellowtel = Mellowtel(
    // other params
    showDebugLogs: true
  );
```

This should start showing: `[MELLOWTEL]: USAGE SUCCESS` in your debug logs within a couple of minutes. If no logs are visible, or you encounter error logs, please contact Mellowtel support.

## Platform Support

This package supports iOS, macos and windows platforms. Android and web are not supported.

Please report any errors in the [github issues](https://github.com/mellowtel-inc/mellowtel-flutter/issues).

## Future Support

We are working on adding support for Android and web platforms. Stay tuned for updates.