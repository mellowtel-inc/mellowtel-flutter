import 'dart:ui';

class ScrapeRequest {
  final String url;
  final int waitBeforeScraping;
  final bool? htmlVisualizer;
  final Size? windowSize;
  final String recordID;
  final bool saveHtml;
  final bool saveMarkdown;
  final String htmlTransformer;
  final String orgId;
  final String? removeCSSselectors;
  final List<Map<String, dynamic>> actions;

  ScrapeRequest(
      {required this.url,
      required this.orgId,
      required this.recordID,
      this.waitBeforeScraping = 0,
      this.htmlVisualizer,
      this.windowSize,
      this.saveHtml = true,
      this.saveMarkdown = true,
      this.htmlTransformer = 'none',
      this.removeCSSselectors,
      this.actions = const []});

  // Factory constructor to create a ScrapeRequest from a JSON map
  factory ScrapeRequest.fromJson(Map<String, dynamic> json) {
    return ScrapeRequest(
        url: json['url'] as String,
        orgId: json['orgId'] as String,
        waitBeforeScraping: json['waitBeforeScraping'] as int,
        htmlVisualizer: json['htmlVisualizer'] as bool?,
        windowSize:
            Size(json['screen_width'] ?? 1024, json['screen_height'] ?? 1024),
        recordID: json['recordID'] as String,
        saveHtml: json['saveHtml'] as bool? ?? true,
        saveMarkdown: json['saveMarkdown'] as bool? ?? true,
        htmlTransformer: json['htmlTransformer'] as String? ?? 'none',
        removeCSSselectors: json['removeCSSselectors'],
        actions: json['actions'] != null
            ? List<Map<String, dynamic>>.from(json['actions'])
            : []);
  }

  // Convert the ScrapeRequest to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'orgId': orgId,
      'recordID': recordID,
      'waitBeforeScraping': waitBeforeScraping,
      'htmlVisualizer': htmlVisualizer,
      'screen_width': windowSize?.width,
      'screen_height': windowSize?.height,
      'saveHtml': saveHtml,
      'saveMarkdown': saveMarkdown,
      'htmlTransformer': htmlTransformer,
      'removeCSSselectors': removeCSSselectors,
      'actions': actions
    };
  }

  @override
  String toString() {
    return 'ScrapeRequest(url: $url, waitBeforeScraping: $waitBeforeScraping, htmlVisualizer: $htmlVisualizer, windowSize: $windowSize, recordID: $recordID)';
  }
}
