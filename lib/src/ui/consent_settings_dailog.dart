import 'package:flutter/material.dart';
import 'package:mellowtel/src/scraping_events.dart';
import 'package:url_launcher/url_launcher.dart';

enum ContainerState {
  optedIn,
  optedOut,
  confirmOptOut,
}

class ConsentSettingsDialog extends StatefulWidget {
  final String appName;
  final String asset;
  final bool initiallyOptedIn;
  final OnOptIn onOptIn;
  final OnOptOut onOptOut;

  const ConsentSettingsDialog({
    super.key,
    required this.appName,
    required this.asset,
    required this.initiallyOptedIn,
    required this.onOptIn,
    required this.onOptOut,
  });

  @override
  ConsentSettingsDialogState createState() => ConsentSettingsDialogState();
}

class ConsentSettingsDialogState extends State<ConsentSettingsDialog> {
  late ContainerState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initiallyOptedIn
        ? ContainerState.optedIn
        : ContainerState.optedOut;
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Container(
          child: !isLandscape || isDesktop
              ? Padding(
                  padding: const EdgeInsets.symmetric(),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                              child: _buildInformationWidget(context)),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildActions(context),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInformationWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            widget.asset,
            height: 64,
            width: 64,
          ),
        ),
        const SizedBox(height: 16.0),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            widget.appName,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8.0),
        Align(
          alignment: Alignment.topLeft,
          child: RichText(
            text: TextSpan(
                text: "Support Status: ",
                children: [
                  TextSpan(
                    text: _state == ContainerState.optedOut
                        ? "Opted out"
                        : "Opted in",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )
                ],
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        const SizedBox(height: 16.0),
        Align(
          alignment: Alignment.center,
          child: Text(
            _getInformationText(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _getInformationText() {
    switch (_state) {
      case ContainerState.optedIn:
        return "Mellowtel is an open-source library that lets you share your unused internet with trusted Al labs & startups who use it to train their models. The developer of this app gets a small share of the revenue. It helps maintain this app free and available. Mellowtel shares your bandwidth only. Security and privacy are 100% guaranteed. It doesn't collect, share, or sell personal information (not even anonymized data).";
      case ContainerState.optedOut:
        return 'You are currently opted out. Your device\'s resources are not being used.';
      case ContainerState.confirmOptOut:
        return 'Mellowtel is used by hundreds of thousands of users around the world. By remaining opted in, you will join this growing network of users. Security, privacy and speed of browsing are 100% guaranteed.\n\nOpting-out might negatively affect the quality of the service offered by this app. Please consider opting-in to help keep this app free and available.';
    }
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
          _buildActionButtons(context),
          const SizedBox(height: 24.0),
          Center(
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse('https://www.mellowtel.it/flutter/');
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

  Widget _buildActionButtons(BuildContext context) {
    switch (_state) {
      case ContainerState.optedIn:
        return Row(
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
                  setState(() {
                    _state = ContainerState.confirmOptOut;
                  });
                },
                child: const Text('Opt Out'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Retu
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        );
      case ContainerState.optedOut:
        return Row(
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
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onOptIn();

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text("Opt In"),
              ),
            ),
          ],
        );
      case ContainerState.confirmOptOut:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                onPressed: () async {
                  await widget.onOptOut();
                  Navigator.pop(context);
                },
                child: const Text("I'm sure"),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        );
    }
  }
}
