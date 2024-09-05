import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mellowtel/src/exceptions.dart';
import 'package:mellowtel/src/model/scrape_request.dart';
import 'package:mellowtel/src/model/scrape_result.dart';
import 'package:mellowtel/src/scraping_events.dart';
import 'package:mellowtel/src/services/dynamo_service.dart';
import 'package:mellowtel/src/services/local_shared_prefs_service.dart';
import 'package:mellowtel/src/services/s3_service.dart';
import 'package:mellowtel/src/ui/consent_dialog.dart';
import 'package:mellowtel/src/webview/macos_webview_manager.dart';
import 'package:mellowtel/src/webview/webview_manager.dart';
import 'package:mellowtel/src/webview/windows_webview_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';

/// The `Mellowtel` class provides methods to manage web scraping tasks
/// using WebView and WebSocket connections.
class Mellowtel {
  /// Creates an instance of `Mellowtel`.
  ///
  /// The [_nodeId] should be a constant specific to the device and is required to identify the node to receieve data from Mellowtel.
  ///
  /// Optional callbacks [onScrapingResult], [onScrapingException], and
  /// [onStorageException] can be provided to handle respective events.
  Mellowtel(
    this._nodeId, {
    this.onScrapingResult,
    this.onScrapingException,
    this.onStorageException,
    required this.appName,
    required this.appIcon,
    required this.incentive,
    required this.yesText,
  }) {
    _webViewManager = Platform.isWindows
        ? WindowsWebViewManager()
        : Platform.isMacOS || Platform.isIOS
            ? MacOSWebViewManager()
            : throw Exception(
                'Only Macos and Windows Platforms are supported.');
  }

  final String _nodeId;
  final _storageService = S3Service();
  LocalSharedPrefsService? _localSharedPrefsService;

  WebSocketChannel? _channel;
  late WebViewManager _webViewManager;

  OnScrapingResult? onScrapingResult;
  OnScrapingException? onScrapingException;
  OnStorageException? onStorageException;

  // Consent dialog values
  final String appName;
  final String appIcon;
  final String incentive;
  final String yesText;

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _initialReconnectDelay = const Duration(seconds: 1);

  /// Tests the crawling process with a given [request].
  ///
  /// This method initializes the WebView, sends the [request] as a message,
  /// and then disposes of the WebView.
  ///
  /// [request] - The scrape request to be tested.
  ///
  /// Use any of the recordIDs 004ie7h3w5, 005ie7h3w5, 006ie7h3w5, 007ie7h3w5 with URL and other params of your choice
  Future<void> test(ScrapeRequest request) async {
    await _webViewManager.initialize();
    await _onMessage(jsonEncode(request.toJson()));
    await _webViewManager.dispose();
  }

  /// Starts the crawling process by establishing a WebSocket connection.
  ///
  /// [resetConsent] can be used to change consent preference by the user.
  Future<void> start(BuildContext context, {bool resetConsent = false}) async {
    // ensure all previous scrapping is stopped in case user.
    await stop();
    _localSharedPrefsService =
        LocalSharedPrefsService(await SharedPreferences.getInstance());
    final previousConsent = _localSharedPrefsService!.getConsent();
    if (previousConsent == null || resetConsent) {
      if (context.mounted) {
        final consent = await _showConsentDialog(
          context,
          appName: appName,
          appIcon: appIcon,
          incentive: incentive,
          yesText: yesText,
        );
        _localSharedPrefsService!.setConsent(consent);
        if (!consent) {
          throw UserConsentDeniedError();
        }
      } else {
        throw Exception(
            'Parent widget providing context is not currently mounted');
      }
    } else if (!previousConsent) {
      throw UserConsentDeniedError();
    }
    await _webViewManager.initialize();
    const version = '0.0.1';

    // flutter-macos or flutter-windows
    final platform = Platform.operatingSystem == 'macos'
        ? 'flutter-macos'
        : Platform.operatingSystem == 'windows'
            ? 'flutter-windows'
            : Platform.operatingSystem == 'ios'
                ? 'flutter-ios'
                : 'flutter';

    final url =
        'wss://7joy2r59rf.execute-api.us-east-1.amazonaws.com/production/?node_id=$_nodeId&version=$version&platform=$platform';
    _connectWebSocket(url);
  }

  void _connectWebSocket(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen((message) {
      _onMessage(message);
    }, onError: (error) {
      developer.log('WebSocket error: $error');
      _handleDisconnection(url);
    }, onDone: () {
      /// 1005 is the close code when termination is voluntarily terminated
      if (_channel != null && _channel?.closeCode != 1005) {
        developer.log('WebSocket Closed with Code: ${_channel?.closeCode}');
        _handleDisconnection(url);
      }
    });
  }

  Future<void> _handleDisconnection(String url) async {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final delay = _initialReconnectDelay * (1 << _reconnectAttempts);
      developer.log(
          'WebSocket disconnected. Reconnecting in ${delay.inSeconds} seconds...');
      Future.delayed(delay, () {
        _reconnectAttempts++;
        _connectWebSocket(url);
      });
    } else {
      developer.log('Max reconnection attempts reached. Giving up.');
    }
  }

  /// Stops the crawling process by closing the WebSocket connection.
  ///
  /// This method closes the WebSocket connection and disposes of the  WebView.
  Future<void> stop() async {
    await _channel?.sink.close();
    await _webViewManager.dispose();
    _channel = null;
  }

  /// To check user's consent
  Future<bool?> checkConsent() async {
    return LocalSharedPrefsService(await SharedPreferences.getInstance())
        .getConsent();
  }

  Future<bool> _showConsentDialog(
    BuildContext context, {
    required String appName,
    required String appIcon,
    required String incentive,
    required String yesText,
  }) async {
    Completer<bool> completer = Completer();
    showDialog(
      context: context,
      barrierColor: Colors.black12.withOpacity(0.6), // Background color
      barrierDismissible: false,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: ConsentDialog(
            appName: appName,
            asset: appIcon,
            incentive: incentive,
            yesText: yesText,
          ),
        );
      },
    ).then((value) {
      final bool? consent = value as bool?;
      completer.complete(consent ?? false);
    });

    return completer.future;
  }

  /// Handles incoming messages from the WebSocket connection.
  ///
  /// This method decodes the incoming [message], processes the scrape request,
  /// and posts the scrape result. Exceptions are handled and passed to the
  /// respective callbacks.
  ///
  /// [message] - The incoming message to be processed.
  Future<void> _onMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);
      final url = data['url'];
      if (url != null) {
        ScrapeRequest scrapeRequest = ScrapeRequest.fromJson(data);
        ScrapeResult scrapeResult = await _runScrapeRequest(scrapeRequest);
        final UploadResult uploadResult = await _postScrapeRequest(scrapeResult,
            url: scrapeRequest.url,
            htmlTransformer: scrapeRequest.htmlTransformer);
        await DynamoService.updateDynamo(uploadResult);
        developer.log('MellowTel: Scrape result posted');
        onScrapingResult?.call(scrapeResult);
      }
    } on ScrapingException catch (e) {
      onScrapingException?.call(e);
    } on StorageException catch (e) {
      onStorageException?.call(e);
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Runs the scrape request using the WebView manager.
  ///
  /// This method crawls the URL specified in the [scrapeRequest] and returns
  /// the scrape result.
  ///
  /// [scrapeRequest] - The scrape request to be processed.
  ///
  /// Returns a [ScrapeResult] containing the scraped data.
  Future<ScrapeResult> _runScrapeRequest(ScrapeRequest scrapeRequest) async {
    try {
      final result = await _webViewManager.crawl(scrapeRequest);
      ScrapeResult scrapeResult = ScrapeResult(
        recordID: scrapeRequest.recordID,
        html: result['html'],
        markdown: result['markdown'],
        screenshot: result['screenshot'],
        orgId: scrapeRequest.orgId,
        finalUrl: result['finalUrl'],
      );
      return scrapeResult;
    } catch (e) {
      throw ScrapingException(e);
    }
  }

  /// Posts the scrape result to the storage service.
  ///
  /// This method uploads the scraped HTML, markdown, and optionally the
  /// screenshot to the storage service. The result is then passed to the
  /// [onScrapingResult] callback.
  ///
  /// [scrapeResult] - The scrape result to be posted.
  Future<UploadResult> _postScrapeRequest(
    ScrapeResult scrapeResult, {
    required String url,
    required String htmlTransformer,
  }) async {
    try {
      final signedUrl =
          await _storageService.getSignedUrls(scrapeResult.recordID);

      final List<Future> requests = [];

      if (scrapeResult.html != null) {
        final htmlRequest = _storageService.uploadHtml(
          signedUrl['uploadURL_html']!,
          scrapeResult.html!,
        );
        requests.add(htmlRequest);
      }
      if (scrapeResult.markdown != null) {
        final markdownRequest = _storageService.uploadMarkdown(
          signedUrl['uploadURL_markDown']!,
          scrapeResult.markdown!,
        );
        requests.add(markdownRequest);
      }
      if (scrapeResult.screenshot != null) {
        final screenshotRequest = _storageService.uploadImage(
          signedUrl['uploadURL_htmlVisualizer']!,
          scrapeResult.screenshot!,
        );
        requests.add(screenshotRequest);
      }

      await Future.wait(requests);
      UploadResult uploadResult = UploadResult(
        recordID: scrapeResult.recordID,
        url: url,
        orgId: scrapeResult.orgId,
        htmlTransformer: htmlTransformer,
      );
      return uploadResult;
    } catch (e) {
      throw StorageException(e);
    }
  }
}
