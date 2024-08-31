import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'dart:developer' as developer;

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String contentType;

  CustomHttpClient({required this.contentType});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Ensure Content-Type is set correctly
    request.headers['Content-Type'] = contentType;
    return _inner.send(request);
  }
}

class S3Service implements StorageService {
  // TODO: Should come from constants file
  final String _getS3SignedUrlsUrl =
      'https://5xub3rkd3rqg6ebumgrvkjrm6u0jgqnw.lambda-url.us-east-1.on.aws/';

  @override
  Future<Map<String, String>> getSignedUrls(String recordID) async {
    final response =
        await http.get(Uri.parse('$_getS3SignedUrlsUrl?recordID=$recordID'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'uploadURL_htmlVisualizer': data['uploadURL_htmlVisualizer'] as String,
        'uploadURL_html': data['uploadURL_html'] as String,
        'uploadURL_markDown': data['uploadURL_markDown'] as String,
      };
    } else {
      throw Exception('Failed to fetch signed URLs');
    }
  }

  @override
  Future<void> uploadHtml(String htmlUrlSigned, String content) async {
    final client = CustomHttpClient(contentType: 'text/html');
    final Stopwatch stopwatch = Stopwatch()..start();

    final response = await client.put(
      Uri.parse(htmlUrlSigned),
      headers: {
        'Content-Type': 'text/html',
        'x-amz-acl': 'public-read',
      },
      body: content,
    );
    developer.log("===>html: ${stopwatch.elapsedMilliseconds}");

    if (response.statusCode != 200) {
      throw Exception('Failed to upload HTML');
    }
  }

  @override
  Future<void> uploadMarkdown(String markdownUrlSigned, String content) async {
    final client = CustomHttpClient(contentType: 'text/markdown');
    final Stopwatch stopwatch = Stopwatch()..start();
    final response = await client.put(
      Uri.parse(markdownUrlSigned),
      headers: {
        'Content-Type': 'text/markdown',
        'x-amz-acl': 'public-read',
      },
      body: content,
    );
    developer.log("===>markdown: ${stopwatch.elapsedMilliseconds}");
    if (response.statusCode != 200) {
      throw Exception('Failed to upload Markdown');
    }
  }

  @override
  Future<void> uploadImage(String imageUrlSigned, Uint8List base64Image) async {
    final client = CustomHttpClient(contentType: 'image/png');
    final Stopwatch stopwatch = Stopwatch()..start();
    final response = await client.put(
      Uri.parse(imageUrlSigned),
      headers: {
        'Content-Type': 'image/png',
        'Content-Encoding': 'base64',
        'x-amz-acl': 'public-read',
      },
      body: base64Image,
    );
    developer.log("===>image: ${stopwatch.elapsedMilliseconds}");

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }
  }
}
