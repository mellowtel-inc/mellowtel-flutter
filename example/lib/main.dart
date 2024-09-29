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
