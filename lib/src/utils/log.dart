import 'dart:developer' as developer;

const bool loggingEnabled = false;

void logMellowtel(String value, {bool showAnyway = false}) {
  if (loggingEnabled || showAnyway) {
    developer.log("[MELLOWTEL]: $value");
  }
}
