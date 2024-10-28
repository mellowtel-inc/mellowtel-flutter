class ConsentDialogConfiguration {
  /// App name displayed in the consent dialog.
  final String appName;

  /// Incentive for enabling mellowtel (e.g., "Get free premium features").
  final String incentive;

  /// Text for the accept button ("Yes" by default).
  final String? acceptButtonText;

  /// Text for the decline button ("No" by default).
  final String? declineButtonText;

  /// App icon displayed in the consent dialog.
  final String? appIcon;

  /// Custom or localized consent dialog message.
  final String? dialogTextOverride;

  const ConsentDialogConfiguration({
    required this.appName,
    required this.incentive,
    this.acceptButtonText,
    this.declineButtonText,
    this.appIcon,
    this.dialogTextOverride,
  });
}