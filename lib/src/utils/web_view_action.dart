import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class WebViewAction {
  Future<void> perform(InAppWebViewController webViewController);
}

class ScrollAction extends WebViewAction {
  final int amount;
  final String direction;

  ScrollAction(this.amount, this.direction);

  @override
  Future<void> perform(dynamic webViewController) async {
    String scrollScript;

    switch (direction) {
      case "up":
        scrollScript = "window.scrollBy(0, -$amount);";
        break;
      case "down":
        scrollScript = "window.scrollBy(0, $amount);";
        break;
      case "left":
        scrollScript = "window.scrollBy(-$amount, 0);";
        break;
      case "right":
        scrollScript = "window.scrollBy($amount, 0);";
        break;
      default:
        throw ArgumentError("Invalid scroll direction: $direction");
    }

    await webViewController.evaluateJavascript(source: scrollScript);
  }
}

class WaitAction extends WebViewAction {
  final int milliseconds;

  WaitAction(this.milliseconds);

  @override
  Future<void> perform(dynamic webViewController) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }
}

class ClickAction extends WebViewAction {
  final String selector;

  ClickAction(this.selector);

  @override
  Future<void> perform(dynamic webViewController) async {
    await webViewController.evaluateJavascript(
      source: """
      (function() {
        const element = document.querySelector('$selector');
        if (element) {
          console.log('Element found: ', element);
          element.click();
          return 'Element clicked';
        } else {
          console.error('Element not found: $selector');
          return 'Element not found';
        }
      })();
      """,
    ).then((result) {
      print(result); // Log the result to the console
    }).catchError((error) {
      print('Error during click action: $error');
    });
  }
}

class PressAction extends WebViewAction {
  final String key;

  PressAction(this.key);

  @override
  Future<void> perform(dynamic webViewController) async {
    await webViewController.evaluateJavascript(
      source: """
      (function() {
        const event = new KeyboardEvent('keydown', { key: '$key' });
        document.dispatchEvent(event);
      })();
      """,
    );
  }
}

class WaitForAction extends WebViewAction {
  final String selector;

  WaitForAction(this.selector);

  @override
  Future<void> perform(dynamic webViewController) async {
    await webViewController.evaluateJavascript(
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
  }
}

class WaitForAndClickAction extends WebViewAction {
  final String selector;

  WaitForAndClickAction(this.selector);

  @override
  Future<void> perform(dynamic webViewController) async {
    await webViewController.evaluateJavascript(
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
  }
}

class FillFormAction extends WebViewAction {
  final Map<String, String> formFields;

  FillFormAction(this.formFields);

  @override
  Future<void> perform(dynamic webViewController) async {
    for (var field in formFields.entries) {
      await webViewController.evaluateJavascript(
        source:
            "document.querySelector('${field.key}').value = '${field.value}';",
      );
    }
  }
}

class ExecuteJsAction extends WebViewAction {
  final String jsCode;

  ExecuteJsAction(this.jsCode);

  @override
  Future<void> perform(dynamic webViewController) async {
    await webViewController.evaluateJavascript(source: jsCode);
  }
}

class InfiniteScrollAction extends WebViewAction {
  final int maxCount;
  final int delay;

  InfiniteScrollAction(this.maxCount, this.delay);

  @override
  Future<void> perform(dynamic webViewController) async {
    for (int i = 0; i < maxCount || maxCount == 0; i++) {
      await webViewController.evaluateJavascript(
        source: "window.scrollTo(0, document.body.scrollHeight);",
      );
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
}

class WebViewActionFactory {
  static WebViewAction create(Map<String, dynamic> action) {
    switch (action["type"]) {
      case "scroll":
        return ScrollAction(action["amount"], action["direction"]);
      case "wait":
        return WaitAction(action["milliseconds"]);
      case "click":
        return ClickAction(action["selector"]);
      case "press":
        return PressAction(action["key"]);
      case "wait_for":
        return WaitForAction(action["selector"]);
      case "wait_for_and_click":
        return WaitForAndClickAction(action["selector"]);
      case "fill_form":
        return FillFormAction(Map<String, String>.from(action["values"]));
      case "execute_js":
        return ExecuteJsAction(action["js"]);
      case "infinite_scroll":
        return InfiniteScrollAction(
            action["max_count"] ?? 1, action["delay"] ?? 500);
      default:
        throw ArgumentError("Invalid action type: ${action["type"]}");
    }
  }
}
