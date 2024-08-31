import 'dart:typed_data';

class ScrapeResult {
  final String? html;
  final String? markdown;
  final String recordID;
  final Uint8List? screenshot;
  final String orgId;
  final String? finalUrl;

  ScrapeResult({
    required this.recordID,
    this.html,
    this.markdown,
    this.screenshot,
    required this.orgId,
    this.finalUrl,
  });
}
