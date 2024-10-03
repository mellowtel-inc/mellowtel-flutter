import 'dart:async';
import 'package:mellowtel/mellowtel.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:mellowtel/src/utils/log.dart';
import 'package:webview_windows/webview_windows.dart' as windows_webview;

import 'webview_manager.dart';

class WindowsWebViewManager extends WebViewManager {
  windows_webview.WebviewController? _webViewController;

  @override
  Future<void> initialize() async {
    logMellowtel("Mellowtel: Initializing Windows WebView");
    _webViewController = windows_webview.WebviewController();
    await _webViewController!.initialize();
  }

  @override
  Future<Map<String, dynamic>> crawl(
    ScrapeRequest request,
  ) async {
    try {
      bool domContentLoaded = false;
      final loadingStateStream = _webViewController!.loadingState;
      loadingStateStream.listen((loadingState) {
        if (loadingState == windows_webview.LoadingState.navigationCompleted) {
          domContentLoaded = true;
        }
      });
      String finalUrl = request.url;
      _webViewController!.url.listen(
        (url) {
          finalUrl = url;
        },
      );

      await _webViewController!.loadUrl(request.url);
      while (!domContentLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(Duration(seconds: request.waitBeforeScraping));
      String? html;
      String? markdown;
      if (request.saveHtml) {
        html = await _webViewController!
            .executeScript('document.documentElement.outerHTML');
        if (request.saveMarkdown) {
          markdown = _convertHtmlToMarkdown(html!);
        }
      }

      return {
        'html': html,
        'markdown': markdown,
        'finalUrl': finalUrl,
      };
    } catch (e) {
      logMellowtel(e.toString());
      throw Exception('Error crawling webpage');
    }
  }

  String _convertHtmlToMarkdown(String html) {
    return html2md.convert(html);
  }

  @override
  Future<void> dispose() async {
    await _webViewController?.dispose();
    _webViewController = null;
  }
}
