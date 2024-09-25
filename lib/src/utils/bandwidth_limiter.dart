import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class BandwidthLimiter {
  static const String _scrapeTimesKey = 'mellowtel_scrape_times';
  static const int maxScrapeTimes = 3;
  static const int maxAllowedTime = 10000;

  final SharedPreferences _prefs;

  BandwidthLimiter(this._prefs);

  Future<void> addScrapeTime(Stopwatch stopwatch) async {
    final time = stopwatch.elapsedMilliseconds;
    stopwatch.stop();
    List<int> scrapeTimes = _prefs.getStringList(_scrapeTimesKey)?.map((e) => int.parse(e)).toList() ?? [];
    if (scrapeTimes.length >= maxScrapeTimes) {
      scrapeTimes.removeAt(0);
    }
    scrapeTimes.add(time);
    await _prefs.setStringList(_scrapeTimesKey, scrapeTimes.map((e) => e.toString()).toList());
  }

  Future<bool> shouldDisconnect() async {
    List<int> scrapeTimes = _prefs.getStringList(_scrapeTimesKey)?.map((e) => int.parse(e)).toList() ?? [];
    if (scrapeTimes.length < maxScrapeTimes) {
      return false;
    }
    int minimumScrapeTime = scrapeTimes.reduce((a, b) => min(a, b));
    return minimumScrapeTime > maxAllowedTime;
  }

  Future<void> resetScrapeTimes() async {
    await _prefs.remove(_scrapeTimesKey);
  }
}