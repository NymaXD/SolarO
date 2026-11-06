import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/lang.dart';

/// Fallback (Android/iOS/desktop): muestra una tarjeta y abre YouTube.
Widget buildYoutubeEmbed(String videoId, {double aspectRatio = 16 / 9}) {
  return _ExternalVideoCard(videoId: videoId, aspectRatio: aspectRatio);
}

class _ExternalVideoCard extends StatelessWidget {
  final String videoId;
  final double aspectRatio;
  const _ExternalVideoCard({required this.videoId, required this.aspectRatio});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showLaunchError(context);
      }
    } on PlatformException {
      if (context.mounted) {
        _showLaunchError(context);
      }
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('learn_video_open_error'))));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Material(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(context),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: AppColors.accent, size: 56),
                SizedBox(height: 8),
                Text('Ver video en YouTube',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
