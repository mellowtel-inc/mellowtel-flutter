class ConsentDialogConfiguration{
  final String appName;
  final String incentive;
  final String? acceptButtonText;
  final String? declineButtonText;
  final String? appIcon;
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