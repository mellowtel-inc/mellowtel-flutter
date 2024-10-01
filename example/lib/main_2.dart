import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewDemo(),
    );
  }
}

class WebViewDemo extends StatefulWidget {
  @override
  _WebViewDemoState createState() => _WebViewDemoState();
}

class _WebViewDemoState extends State<WebViewDemo> {
  InAppWebViewController? _webViewController;
  final String initialUrl = "https://www.olostep.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WebView Demo"),
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                // Perform actions after the page has loaded
                await _performActions();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performActions() async {
    if (_webViewController == null) return;

    // Example actions: scroll down 1000px, wait 1 second, scroll down another 1000px, wait 1 second
    List<Map<String, dynamic>> actions = [
      {"scroll_y": 1000},
      {"wait": 4000},
      {"scroll_y": 1000},
      {"wait": 1000},
    ];

    for (var action in actions) {
      if (action.containsKey("scroll_y")) {
        int scrollY = action["scroll_y"];
        await _webViewController!.evaluateJavascript(
          source: "window.scrollBy(0, $scrollY);",
        );
      } else if (action.containsKey("wait")) {
        int waitTime = action["wait"];
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }
  }
}