import 'dart:async';

import 'package:mellowtel/mellowtel.dart';

abstract class WebViewManager {
  Future<void> initialize();
  Future<Map<String, dynamic>> crawl(ScrapeRequest request);
  Future<void> dispose();
}
