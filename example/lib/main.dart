import 'package:flutter/material.dart';
import 'package:mellowtel/mellowtel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HTML Extractor Manager'),
        ),
        body: const HtmlExtractorWidget(),
      ),
    );
  }
}

class HtmlExtractorWidget extends StatefulWidget {
  const HtmlExtractorWidget({super.key});

  @override
  HtmlExtractorWidgetState createState() => HtmlExtractorWidgetState();
}

class HtmlExtractorWidgetState extends State<HtmlExtractorWidget> {
  final Mellowtel mellowtel = Mellowtel("123",
      appName: 'King Kong',
      appIcon: 'asset/logo.png',
      incentive: 'Earn 500 coins in Sling Kong',
      yesText: 'FREE Coins!',
      showDebugLogs: true);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await mellowtel.start(context, showDefaultConsentDialog: true,
                    onOptIn: () async {
                  // Handle enabling services when consent is provided.
                }, onOptOut: () async {
                  // Handle disabling services if consent is denied.
                });
              },
              child: const Text('Start'),
            ),
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await mellowtel.showConsentSettingsPage(context,
                    onOptIn: () async {
                  // Handle enabling services when consent is provided.
                }, onOptOut: () async {
                  // Handle disabling services if consent is denied.
                });
              },
              child: const Text('Settings'),
            ),
          ),
          const SizedBox(height: 16.0),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await mellowtel.test(
                    ScrapeRequest(
                        recordID: '005ie7h3w5',
                        url: 'https://www.google.com',
                        waitBeforeScraping: 1,
                        saveHtml: true,
                        saveMarkdown: true,
                        htmlVisualizer: true,
                        orgId: 'mellowtel',
                        htmlTransformer: 'none',
                        removeCSSselectors: 'default',
                        actions: [
                          
                          {"type": "wait", "milliseconds": 2000},
                          // {"type": "fill_form", "values": {"#tsf > div:nth-child(1) > div.A7Yvie.Epl37 > div.zGVn2e > div.SDkEP > div > textarea": "TEST"}},
                          { "type": "click", "selector": "#tsf > div:nth-child(1) > div.A7Yvie.Epl37 > div.zGVn2e > div.SDkEP > div > textarea" },
                          {"type": "wait", "milliseconds": 1000},
                          {"type": "write", "text": "TEST"},
                          {"type": "wait", "milliseconds": 1000},
                          {"type": "press", "key": "Enter"},
                          {"type": "wait", "milliseconds": 1000},
                        ]),
                    context: context);
              },
               
              child: const Text('Test'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mellowtel.stop();
    super.dispose();
  }
}
