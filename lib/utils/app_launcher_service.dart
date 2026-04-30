import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncherService {
  static final AppLauncherService instance = AppLauncherService._();
  AppLauncherService._();
  Future<void> openGoogleForm(BuildContext context) async {
    final url = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSd9--oSe4vAVGW5ju1Wf4F0TRR56VO0KHTtXGbL3daJbW8fUA/viewform?usp=dialog',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkError)),
      );
    }
  }
}
