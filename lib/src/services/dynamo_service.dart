import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class UploadResult {
  final String recordID;
  final String url;
  final String orgId;
  final String htmlTransformer;
  final String? finalUrl;

  UploadResult(
      {required this.recordID,
      required this.url,
      required this.orgId,
      this.htmlTransformer = 'none',
      this.finalUrl});
}

class DynamoService {
  static const String baseUrl =
      "https://zuaq4uywadlj75qqkfns3bmoom0xpaiz.lambda-url.us-east-1.on.aws/";

  static Future<void> updateDynamo(UploadResult uploadResult) async {
    final bodyData = {
      "recordID": uploadResult.recordID,
      "url": uploadResult.url,
      "orgId": uploadResult.orgId,
      "htmlTransformer": uploadResult.htmlTransformer,
      "final_url": uploadResult.finalUrl,
      "htmlFileName": "text_${uploadResult.recordID}.html",
      "markdownFileName": "markDown_${uploadResult.recordID}.md",
      "htmlVisualizerFileName": "image_${uploadResult.recordID}.png",
    };

    final requestOptions = http.Request("POST", Uri.parse(baseUrl))
      ..headers["Content-Type"] = "text/plain"
      ..body = jsonEncode(bodyData);

    developer.log(
        "[updateDynamo]: Sending data to server => ${uploadResult.recordID}");

    try {
      final response = await http.Client().send(requestOptions);
      if (response.statusCode == 200) {
        final data = await response.stream.bytesToString();
        developer.log("Response from server: $data");
      } else {
        throw Exception("Network response was not ok");
      }
    } catch (error) {
      throw Exception("Failed to report: $error");
    }
  }
}
