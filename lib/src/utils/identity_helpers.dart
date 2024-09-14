import 'dart:math';

import 'package:mellowtel/src/services/local_shared_prefs_service.dart';

Future<String> getOrGenerateIdentifier(
    String configurationKey, LocalSharedPrefsService prefsService) async {
  final storedIdentifier = prefsService.getIdentifier();

  if (storedIdentifier != null &&
      storedIdentifier.startsWith('mllwtl_flutter_$configurationKey')) {
    return storedIdentifier;
  } else if (storedIdentifier != null &&
      storedIdentifier.startsWith('mllwtl_flutter_')) {
    final newIdentifier = await generateIdentifier(configurationKey,
        justUpdateKey: true,
        previousIdentifier: storedIdentifier,
        prefsService: prefsService);
    return newIdentifier;
  } else {
    final newIdentifier =
        await generateIdentifier(configurationKey, prefsService: prefsService);
    return newIdentifier;
  }
}

Future<String> generateIdentifier(
  String configurationKey, {
  bool justUpdateKey = false,
  String previousIdentifier = '',
  required LocalSharedPrefsService prefsService,
}) async {
  final randomString = justUpdateKey
      ? extractRandomString(previousIdentifier)
      : generateRandomString(10);
  final identifier = 'mllwtl_flutter_${configurationKey}_$randomString';
  await prefsService.setIdentifier(identifier);
  return identifier;
}

String extractRandomString(String identifier) {
  final parts = identifier.split('_');
  if (parts.length >= 3) {
    return parts.last;
  }
  return generateRandomString(10); // Fallback in case the identifier format is unexpected
}

String generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
      .join();
}