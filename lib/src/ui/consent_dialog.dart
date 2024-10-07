import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsentDialog extends StatelessWidget {
  final String appName;
  final String asset;
  final String incentive;
  final String yesText;

  const ConsentDialog({
    super.key,
    required this.appName,
    required this.asset,
    required this.incentive,
    required this.yesText,
  });

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return SafeArea(
      child: Container(
        child: !isLandscape || isDesktop
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    // vertical: 8.0,
                    ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInformationWidget(context),
                      const SizedBox(height: 20.0),
                      Center(child: _buildActions(context)),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        child: SingleChildScrollView(
                            child: _buildInformationWidget(context)),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        child: _buildActions(context),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.shield_outlined),
                  ),
                  Text(
                    "Secure\ncloud",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const Column(
                children: [Icon(Icons.sync_alt), Text("")],
              ),
              Column(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.phone_android_outlined),
                  ),
                  Text(
                    "Your\ndevice",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const Column(
                children: [Icon(Icons.sync_alt), Text("")],
              ),
              Column(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.language),
                  ),
                  Text(
                    "Public\nwebsite",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Returns false on decline
                  },
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(true); // Returns true on acceptance
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                  ),
                  child: Text("Yes $yesText"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Center(
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse('https://www.mellowtel.com/mellowtel-privacy-policy/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Text(
                'Read our Privacy Policy and End User License Agreement',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Icon
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            asset,
            height: 64,
            width: 64,
          ),
        ),
        const SizedBox(height: 16.0),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            appName,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16.0),
        Align(
          alignment: Alignment.center,
          child: Text(
            '$incentive. If you click on “Yes”, you can share your unused bandwidth with Mellowtel to enable access to public websites helping keep the app free.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'It shares internet bandwidth only. No personal information is collected.\n\nYour participation is totally optional. You can opt-in or out at any moment from the settings page.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
