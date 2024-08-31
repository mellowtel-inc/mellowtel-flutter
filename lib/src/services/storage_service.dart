import 'dart:async';
import 'dart:typed_data';

abstract class StorageService {
  Future<Map<String, String>> getSignedUrls(String recordID);

  Future<void> uploadHtml(String htmlUrlSigned, String content);

  Future<void> uploadMarkdown(String markdownUrlSigned, String content);

  Future<void> uploadImage(String imageUrlSigned, Uint8List base64Image);
}
