import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class RateLimiter {
  static const String _dailyRateLimitKey = 'mellowtel_daily_rate_limit';
  static const String _dailyTimestampKey =
      'mellowtel_daily_rate_limit_timestamp';
  static const String _minuteRateLimitKey = 'mellowtel_minute_rate_limit';
  static const String _minuteTimestampKey =
      'mellowtel_minute_rate_limit_timestamp';
  static const int maxDailyRequests = 300;
  static const int maxMinuteRequests = 4;
  static const Duration dailyRefreshInterval = Duration(hours: 24);
  static const Duration minuteRefreshInterval = Duration(minutes: 1);

  final SharedPreferences _prefs;

  RateLimiter(this._prefs);
  Future<bool> getIfDailyRateLimitReached() async {
    final int requestCount = _prefs.getInt(_dailyRateLimitKey) ?? 0;
    final int timestamp = _prefs.getInt(_dailyTimestampKey) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (now - timestamp > dailyRefreshInterval.inMilliseconds) {
      await resetDailyRateLimitData(now);
      return false;
    }

    return requestCount >= maxDailyRequests;
  }

  Future<bool> getIfMinuteRateLimitReached() async {
    final int requestCount = _prefs.getInt(_minuteRateLimitKey) ?? 0;
    final int timestamp = _prefs.getInt(_minuteTimestampKey) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (now - timestamp > minuteRefreshInterval.inMilliseconds) {
      await resetMinuteRateLimitData(now);
      return false;
    }

    return requestCount >= maxMinuteRequests;
  }

  Future<void> increment() async {
    final int minuteRequestCount = _prefs.getInt(_minuteRateLimitKey) ?? 0;
    await _prefs.setInt(_minuteRateLimitKey, minuteRequestCount + 1);

    final int dailyRequestCount = _prefs.getInt(_dailyRateLimitKey) ?? 0;
    await _prefs.setInt(_dailyRateLimitKey, dailyRequestCount + 1);
  }

  Future<void> resetDailyRateLimitData(int now) async {
    await _prefs.setInt(_dailyRateLimitKey, 0);
    await _prefs.setInt(_dailyTimestampKey, now);
  }

  Future<void> resetMinuteRateLimitData(int now) async {
    await _prefs.setInt(_minuteRateLimitKey, 0);
    await _prefs.setInt(_minuteTimestampKey, now);
  }

  Future<int> getDailyRequestCount() async {
    return _prefs.getInt(_dailyRateLimitKey) ?? 0;
  }

  Future<int> getMinuteRequestCount() async {
    return _prefs.getInt(_minuteRateLimitKey) ?? 0;
  }

  Future<int> getDailyTimestamp() async {
    return _prefs.getInt(_dailyTimestampKey) ?? 0;
  }

  Future<int> getMinuteTimestamp() async {
    return _prefs.getInt(_minuteTimestampKey) ?? 0;
  }
}
