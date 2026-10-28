import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Fallback (Android/iOS/desktop): muestra una tarjeta y abre YouTube.
Widget buildYoutubeEmbed(String videoId, {double aspectRatio = 16 / 9}) {
  return _ExternalVideoCard(videoId: videoId, aspectRatio: aspectRatio);
}

class _ExternalVideoCard extends StatelessWidget {
  final String videoId;
  final double aspectRatio;
  const _ExternalVideoCard({required this.videoId, required this.aspectRatio});

  Future<void> _open() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          onTap: _open,
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
