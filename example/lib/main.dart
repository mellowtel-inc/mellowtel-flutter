import 'package:flutter/material.dart';
import 'package:mellowtel/mellowtel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}): super(key: key);

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
  const HtmlExtractorWidget({Key key}): super(key: key);

  @override
  HtmlExtractorWidgetState createState() => HtmlExtractorWidgetState();
}

class HtmlExtractorWidgetState extends State<HtmlExtractorWidget> {
  final Mellowtel mellowtel = Mellowtel(
    "123",
    appName: 'King Kong',
    appIcon: 'asset/logo.png',
    incentive: 'Earn 500 coins in Sling Kong',
    yesText: 'FREE Coins!',
  );

  @override
  void initState() {
    
    // TODO: Enable temporarily for debugging purposes to verify if the data is processed correctly

    // mellowtel.onScrapingResult = (result) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Scraping result: ${result.recordID}'),
    //     ),
    //   );
    // };
    // mellowtel.onScrapingException = (error) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Scraping error: ${error.message}'),
    //     ),
    //   );
    // };
    // mellowtel.onStorageException = (error) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Storage error: $error'),
    //     ),
    //   );
    // };

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
              onPressed: () {
                /// Test requests to make sure the scraping and uploading works correctly
                ///
                /// Don't trigger after calling `start()`
                mellowtel.test(
                  ScrapeRequest(
                      recordID: '005ie7h3w5',
                      url: 'https://www.mellowtel.dev/',
                      waitBeforeScraping: 1,
                      saveHtml: true,
                      saveMarkdown: true,
                      htmlVisualizer: true,
                      orgId: 'mellowtel',
                      htmlTransformer: 'none',
                      removeCSSselectors: 'default'),
                );
              },
              child: const Text('Demo request'),
            ),
          ),
          const SizedBox(height: 16.0),
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
