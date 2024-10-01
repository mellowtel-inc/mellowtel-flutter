import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mellowtel/mellowtel.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:mellowtel/src/utils/frame_manager.dart';
import 'package:mellowtel/src/utils/log.dart';

import 'webview_manager.dart';

class MacOSWebViewManager extends WebViewManager {
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webViewController;
  Completer<void>? _pageLoadCompleter;

  @override
  Future<void> initialize() async {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = loggingEnabled;
    _headlessWebView = HeadlessInAppWebView(onWebViewCreated: (controller) {
      logMellowtel("MellowTel: Webview created!");
      _webViewController = controller;
    }, onLoadStop: (controller, url) async {
      _pageLoadCompleter?.complete();
    }, onProgressChanged: (_, int x) {
    }, );

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
    if (action.containsKey("scroll_y")) {
      int scrollY = action["scroll_y"];
      await _webViewController!.evaluateJavascript(
        source: "window.scrollBy(0, $scrollY);",
      );
    } else if (action.containsKey("scroll_x")) {
      int scrollX = action["scroll_x"];
      await _webViewController!.evaluateJavascript(
        source: "window.scrollBy($scrollX, 0);",
      );
    } else if (action.containsKey("wait")) {
      int waitTime = action["wait"];
      await Future.delayed(Duration(milliseconds: waitTime));
    } else if (action.containsKey("click")) {
      String selector = action["click"];
      await _webViewController!.evaluateJavascript(
        source: "document.querySelector('$selector').click();",
      );
    } else if (action.containsKey("wait_for")) {
      String selector = action["wait_for"];
      await _webViewController!.evaluateJavascript(
        source: """
        (function() {
          return new Promise((resolve) => {
            const observer = new MutationObserver((mutations, obs) => {
              if (document.querySelector('$selector')) {
                obs.disconnect();
                resolve();
              }
            });
            observer.observe(document, { childList: true, subtree: true });
          });
        })();
        """,
      );
    } else if (action.containsKey("wait_for_and_click")) {
      String selector = action["wait_for_and_click"];
      await _webViewController!.evaluateJavascript(
        source: """
        (function() {
          return new Promise((resolve) => {
            const observer = new MutationObserver((mutations, obs) => {
              if (document.querySelector('$selector')) {
                document.querySelector('$selector').click();
                obs.disconnect();
                resolve();
              }
            });
            observer.observe(document, { childList: true, subtree: true });
          });
        })();
        """,
      );
    } else if (action.containsKey("fill_form")) {
      Map<String, String> formFields = Map<String, String>.from(action["fill_form"]);
      for (var field in formFields.entries) {
        await _webViewController!.evaluateJavascript(
          source: "document.querySelector('${field.key}').value = '${field.value}';",
        );
      }
    } else if (action.containsKey("execute_js")) {
      String jsCode = action["execute_js"];
      await _webViewController!.evaluateJavascript(source: jsCode);
    } else if (action.containsKey("infinite_scroll")) {
      Map<String, dynamic> config = action["infinite_scroll"];
      int maxCount = config["max_count"] ?? 1;
      int delay = config["delay"] ?? 500;
      String? endClickSelector = config["end_click"]?["selector"];
      for (int i = 0; i < maxCount || maxCount == 0; i++) {
        await _webViewController!.evaluateJavascript(
          source: "window.scrollTo(0, document.body.scrollHeight);",
        );
        await Future.delayed(Duration(milliseconds: delay));
        if (endClickSelector != null) {
          await _webViewController!.evaluateJavascript(
            source: "document.querySelector('$endClickSelector').click();",
          );
        }
      }
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