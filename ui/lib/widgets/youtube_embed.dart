import 'package:flutter/material.dart';

import 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart' as impl;

/// Reproductor de YouTube embebido en la página (web).
/// En otras plataformas cae al botón que abre YouTube.
Widget buildYoutubeEmbed(String videoId, {double aspectRatio = 16 / 9}) {
  return impl.buildYoutubeEmbed(videoId, aspectRatio: aspectRatio);
}
