import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:mellowtel/mellowtel.dart';
import 'package:mellowtel/src/utils/frame_manager.dart';
import 'package:mellowtel/src/utils/log.dart';
import 'package:mellowtel/src/utils/web_view_action.dart';

import 'webview_manager.dart';

class MacOSWebViewManager extends WebViewManager {
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webViewController;
  Completer<void>? _pageLoadCompleter;

  @override
  Future<void> initialize() async {
    PlatformInAppWebViewController.debugLoggingSettings.enabled =
        loggingEnabled;
    _headlessWebView = HeadlessInAppWebView(
      onWebViewCreated: (controller) {
        logMellowtel("MellowTel: Webview created!");
        _webViewController = controller;
      },
      onLoadStop: (controller, url) async {
        _pageLoadCompleter?.complete();
      },
      onProgressChanged: (_, int x) {},
    );

    await _headlessWebView!.run();
  }

  @override
  Future<Map<String, dynamic>> crawl(
    ScrapeRequest request,
  ) async {
    if (request.windowSize != null) {
      await _headlessWebView!.setSize(request.windowSize!);
    }
    await _loadUrlAndWait(request.url, request.removeCSSselectors);
    await _performActions(request.actions);
    await Future.delayed(Duration(seconds: request.waitBeforeScraping));
    final result = await _webViewController!
        .evaluateJavascript(source: 'document.documentElement.outerHTML');
    final html = result?.toString() ?? '';
    final markdown = await _convertHtmlToMarkdown(html);
    Uint8List? screenshot;
    if (request.htmlVisualizer ?? false) {
      screenshot = await _webViewController!.takeScreenshot();
    }
    final finalUri = await _webViewController!.getUrl();
    final String? finalUrl = finalUri?.uriValue.toString();

    return {
      'html': html,
      'markdown': markdown,
      'screenshot': screenshot,
      'finalUrl': finalUrl,
    };
  }

  Future<void> _loadUrlAndWait(String url, String? removeCSSselectors) async {
    _pageLoadCompleter = Completer<void>();
    await FrameManager().waitForIdleFrames();
    await _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    await _pageLoadCompleter!.future;
    // Inject and execute JavaScript to remove selectors
    if (removeCSSselectors != null && removeCSSselectors.isNotEmpty) {
      final jsCode = '''
      (function() {
        function removeSelectorsFromDocument(document, selectorsToRemove) {
          const defaultSelectorsToRemove = [
            "nav", "footer", "script", "style", "noscript", "svg", '[role="alert"]', '[role="banner"]', '[role="dialog"]', '[role="alertdialog"]', '[role="region"][aria-label*="skip" i]', '[aria-modal="true"]'
          ];
          if (selectorsToRemove.length === 0) selectorsToRemove = defaultSelectorsToRemove;
          selectorsToRemove.forEach((selector) => {
            const elements = document.querySelectorAll(selector);
            elements.forEach((element) => element.remove());
          });
        }

        let removeCSSselectors = ${removeCSSselectors == "default" ? "[]" : removeCSSselectors};
        if (removeCSSselectors === "default") {
          removeSelectorsFromDocument(document, []);
        } else if (removeCSSselectors !== "" && removeCSSselectors !== "none") {
          try {
            let selectors = JSON.parse(removeCSSselectors);
            removeSelectorsFromDocument(document, selectors);
          } catch (e) {
            console.log("Error parsing removeCSSselectors =>", e);
          }
        }
      })();
    ''';
      await _webViewController!.evaluateJavascript(source: jsCode);
    }
  }

  Future<void> _performActions(List<Map<String, dynamic>> actions) async {
    if (_webViewController == null) return;

    for (var action in actions) {
      WebViewAction webViewAction = WebViewActionFactory.create(action);
      try {
        await webViewAction.perform(_webViewController!);
      } catch (e) {
        logMellowtel("Failed to perform action $action for $e");
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _headlessWebView?.dispose();
    _headlessWebView = null;
    _webViewController = null;
  }
}

// Top-level function to be run in an isolate
String _convertHtmlToMarkdownInIsolate(String html) {
  return html2md.convert(html);
}

Future<String> _convertHtmlToMarkdown(String html) async {
  return await compute(_convertHtmlToMarkdownInIsolate, html);
}
