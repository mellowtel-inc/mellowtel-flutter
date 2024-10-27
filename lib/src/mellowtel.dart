import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mellowtel/src/exceptions.dart';
import 'package:mellowtel/src/model/consent_dialog_configuration.dart';
import 'package:mellowtel/src/model/scrape_request.dart';
import 'package:mellowtel/src/model/scrape_result.dart';
import 'package:mellowtel/src/scraping_events.dart';
import 'package:mellowtel/src/services/dynamo_service.dart';
import 'package:mellowtel/src/services/local_shared_prefs_service.dart';
import 'package:mellowtel/src/services/s3_service.dart';
import 'package:mellowtel/src/ui/consent_dialog.dart';
import 'package:mellowtel/src/ui/consent_settings_dailog.dart';
import 'package:mellowtel/src/utils/log.dart';
import 'package:mellowtel/src/utils/rate_limiter.dart';
import 'package:mellowtel/src/webview/macos_webview_manager.dart';
import 'package:mellowtel/src/webview/webview_manager.dart';
import 'package:mellowtel/src/webview/windows_webview_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:mellowtel/src/utils/identity_helpers.dart'; // Import the identity helpers
import 'package:connectivity_plus/connectivity_plus.dart'; // Import the connectivity_plus package

/// The `Mellowtel` class provides methods to manage web scraping tasks
/// using WebView and WebSocket connections.
class Mellowtel {
  /// Creates an instance of `Mellowtel`.
  ///
  /// The [_configurationKey] should be a constant specific to the device and is required to identify the node to receieve data from Mellowtel.
  ///
  /// Optional callbacks [onScrapingResult], [onScrapingException], and
  /// [onStorageException] can be provided to handle respective events.
  Mellowtel(
    this._configurationKey, {
    required this.dialogConfiguration,
    this.showDebugLogs = false,
  }) {
    _webViewManager = Platform.isWindows
        ? WindowsWebViewManager()
        : Platform.isMacOS || Platform.isIOS
            ? MacOSWebViewManager()
            : throw Exception(
                'Only iOS, Macos and Windows Platforms are supported.');
  }

  final String _configurationKey;
  final ConsentDialogConfiguration dialogConfiguration;
  final bool showDebugLogs;

  final _storageService = S3Service();
  WebSocketChannel? _channel;
  late WebViewManager _webViewManager;

  LocalSharedPrefsService? _sharedPrefsService;
  Future<LocalSharedPrefsService> get sharedPrefsService async =>
      _sharedPrefsService ??
      LocalSharedPrefsService(await SharedPreferences.getInstance());

  final Connectivity connectivity = Connectivity();

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _initialReconnectDelay = const Duration(seconds: 1);

  bool _initialized = false;

  Timer? _fakeSocket;

  /// Only for internal use
  ///
  /// Tests the crawling process with a given [request].
  ///
  /// This method initializes the WebView, sends the [request] as a message,
  /// and then disposes of the WebView.
  ///
  /// [request] - The scrape request to be tested.
  ///
  /// Use any of the recordIDs 004ie7h3w5, 005ie7h3w5, 006ie7h3w5, 007ie7h3w5 with URL and other params of your choice
  Future<void> test(ScrapeRequest request, {BuildContext? context}) async {
    await _webViewManager.initialize();
    // ignore: use_build_context_synchronously
    await _onMessage(jsonEncode(request.toJson()), context: context);
    await _webViewManager.dispose();
  }

  /// Starts the crawling process by establishing a WebSocket connection.
  ///
  /// [onOptIn] and [onOptOut] allow you to enable or disable services based on user's choice.
  /// They are only called the first time user makes a choice or if changes their consent later.
  ///
  /// [showConsentDialog]: `true` by default. Set `false` if you have to show the permission dialog manually or somewhere else
  Future<void> start(BuildContext context,
      {required OnOptIn onOptIn,
      required OnOptOut onOptOut,
      bool showConsentDialog = true}) async {
    if (_initialized) return;
    try {
      bool? consent = (await sharedPrefsService).getConsent();
      if (consent == null) {
        if (!showConsentDialog) {
          logMellowtel(
              """Not showing permission consent dialog since [showConsentDialog] is set to `false`.
              
               Either call [start] with  [showConsentDialog] where you would like user to provide consent or set user permission via [optIn] or [optOut] methods manually.""");
          return;
        }
        if (context.mounted) {
          consent = await _showConsentDialog(context,
              appName: dialogConfiguration.appName,
              appIcon: dialogConfiguration.appIcon,
              incentive: dialogConfiguration.incentive,
              acceptButtonText: dialogConfiguration.acceptButtonText,
              declineButtonText: dialogConfiguration.declineButtonText,
              dialogTextOverride: dialogConfiguration.dialogTextOverride);
          consent ? await onOptIn() : await onOptOut();

          await (await sharedPrefsService).setConsent(consent);
        } else {
          throw (Exception(
              '[Mellowtel]: Parent widget providing context is not currently mounted'));
        }
      }

      if (consent) {
        await _startScraping();
      }
    } catch (e) {
      logMellowtel('$e');
    }
  }

  Future<void> showConsentSettingsPage(BuildContext context,
      {required OnOptIn onOptIn, required OnOptOut onOptOut}) async {
    final previousConsent = (await sharedPrefsService).getConsent();
    final nodeId = await getOrGenerateIdentifier(
        _configurationKey, (await sharedPrefsService));
    if (context.mounted) {
      await _showConsentSettingsDialog(context,
          appName: dialogConfiguration.appName,
          appIcon: dialogConfiguration.appIcon,
          consent: previousConsent ?? false, onOptIn: () async {
        await (await sharedPrefsService).setConsent(true);
        await _startScraping();
        await onOptIn();
      }, onOptOut: () async {
        await (await sharedPrefsService).setConsent(false);
        await stop();
        await onOptOut();
      }, nodeId: nodeId);
    }
  }

  /// Provide consent on behalf of user
  Future<void> optIn() async {
    final previousConsent = (await sharedPrefsService).getConsent();
    if (previousConsent == null || !previousConsent) {
      await (await sharedPrefsService).setConsent(true);
      await _startScraping();
    }
  }

  /// Revoke consent on behalf of user
  Future<void> optOut() async {
    final previousConsent = (await sharedPrefsService).getConsent();
    if (previousConsent != null && previousConsent) {
      await (await sharedPrefsService).setConsent(false);
      await stop();
    }
  }

  /// Stops the crawling process by closing the WebSocket connection.
  ///
  /// This method closes the WebSocket connection and disposes of the  WebView.
  Future<void> stop() async {
    _fakeSocket?.cancel();
    await _channel?.sink.close();
    await _webViewManager.dispose();
    _channel = null;
    _initialized = false;
  }

  /// To check user's consent
  Future<bool?> checkConsent() async {
    return LocalSharedPrefsService(await SharedPreferences.getInstance())
        .getConsent();
  }

  Future<void> _startScraping() async {
    _initialized = true;
    await _webViewManager.initialize();
    const version = '0.0.3';

    // flutter-macos or flutter-windows
    final platform = Platform.operatingSystem == 'macos'
        ? 'flutter-macos'
        : Platform.operatingSystem == 'windows'
            ? 'flutter-windows'
            : Platform.operatingSystem == 'ios'
                ? 'flutter-ios'
                : 'flutter';

    // Generate the identifier using the node ID
    final identifier = await getOrGenerateIdentifier(
        _configurationKey, (await sharedPrefsService));

    final url =
        'wss://7joy2r59rf.execute-api.us-east-1.amazonaws.com/production/?node_id=$identifier&version=$version&platform=$platform';

    // Check if the user is on Wi-Fi or Ethernet before connecting to WebSocket
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      _connectWebSocket(url);
    } else {
      logMellowtel('Not connected to Wi-Fi. WebSocket connection aborted.');
    }
  }

  void _connectWebSocket(String url, {bool test = false}) {
    if (test) {
      _fakeSocket = Timer.periodic(const Duration(seconds: 4), (_) {
        _onMessage(jsonEncode(ScrapeRequest(
                recordID: '005ie7h3w5',
                url: 'https://www.mellowtel.dev/',
                waitBeforeScraping: 1,
                saveHtml: true,
                saveMarkdown: true,
                htmlVisualizer: true,
                orgId: 'mellowtel',
                htmlTransformer: 'none',
                removeCSSselectors: 'default')
            .toJson()));
      });
      return;
    }
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen((message) {
      _onMessage(message);
    }, onDone: () {
      /// 1005 is the close code when termination is voluntarily terminated
      if (_channel != null && _channel?.closeCode != 1005) {
        logMellowtel('WebSocket Closed with Code: ${_channel?.closeCode}');
        _handleDisconnection(url);
      }
    });
  }

  Future<void> _handleDisconnection(String url) async {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      final delay = _initialReconnectDelay * (1 << _reconnectAttempts);
      logMellowtel(
          'WebSocket disconnected. Reconnecting in ${delay.inSeconds} seconds...');
      Future.delayed(delay, () {
        _reconnectAttempts++;
        _connectWebSocket(url);
      });
    } else {
      logMellowtel('Max reconnection attempts reached. Giving up.');
    }
  }

  Future<bool> _showConsentDialog(
    BuildContext context, {
    required String appName,
    required String? appIcon,
    required String incentive,
    required String? acceptButtonText,
    required String? declineButtonText,
    required String? dialogTextOverride,
  }) async {
    Completer<bool> completer = Completer();
    showDialog(
      context: context,
      barrierColor: Colors.black12.withOpacity(0.6), // Background color
      barrierDismissible: false,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: ConsentDialog(
            appName: appName,
            appIcon: appIcon,
            incentive: incentive,
            acceptButtonText: acceptButtonText,
            declineButtonText: declineButtonText,
            dialogTextOverride: dialogTextOverride,
          ),
        );
      },
    ).then((value) {
      final bool? consent = value as bool?;
      completer.complete(consent ?? false);
    });

    return completer.future;
  }

  Future<void> _showConsentSettingsDialog(BuildContext context,
      {required String appName,
      required String? appIcon,
      required OnOptIn onOptIn,
      required OnOptOut onOptOut,
      required bool consent,
      required String nodeId}) async {
    Completer<void> completer = Completer();
    showDialog(
      context: context,
      barrierColor: Colors.black12.withOpacity(0.6), // Background color
      barrierDismissible: false,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: ConsentSettingsDialog(
            appName: appName,
            appIcons: appIcon,
            initiallyOptedIn: consent,
            onOptIn: onOptIn,
            onOptOut: onOptOut,
            nodeId: nodeId,
          ),
        );
      },
    ).then((value) {
      completer.complete();
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
  Future<void> _onMessage(dynamic message, {BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    final rateLimiter = RateLimiter(prefs);

    if (await rateLimiter.getIfDailyRateLimitReached()) {
      logMellowtel(
          'Mellowtel: Daily rate limit reached. Closing WebSocket connection.');
      await stop();
      return;
    }

    if (await rateLimiter.getIfMinuteRateLimitReached()) {
      developer
          .log('Mellowtel: Per-minute rate limit reached. Skipping request.');
      return;
    }

    try {
      final data = jsonDecode(message);
      final url = data['url'];
      if (url != null) {
        // Increase rate limit prior only so more requests aren't queued.
        await rateLimiter.increment();

        ScrapeRequest scrapeRequest = ScrapeRequest.fromJson(data);

        ScrapeResult scrapeResult = await _runScrapeRequest(scrapeRequest);
        if (context != null && scrapeResult.screenshot != null) {
          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
                builder: (context) => Scaffold(
                      appBar: AppBar(),
                      body: SizedBox.expand(
                        child: Image.memory(
                          scrapeResult.screenshot!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )),
          );
        }
        final UploadResult uploadResult = await _postScrapeRequest(scrapeResult,
            url: scrapeRequest.url,
            htmlTransformer: scrapeRequest.htmlTransformer);
        await DynamoService.updateDynamo(uploadResult);
        logMellowtel('MellowTel: Scrape result posted');
        if (showDebugLogs) logMellowtel("USAGE SUCCESS", showAnyway: true);
      }
    } catch (e) {
      if (showDebugLogs) logMellowtel("USAGE ERROR: $e", showAnyway: true);
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
