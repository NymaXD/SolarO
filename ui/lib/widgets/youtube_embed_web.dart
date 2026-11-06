import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Registro de viewTypes ya creados (no se puede registrar dos veces).
final Set<String> _registered = {};

/// Reproductor de YouTube embebido con un iframe (solo web).
Widget buildYoutubeEmbed(String videoId, {double aspectRatio = 16 / 9}) {
  final viewType = 'youtube-embed-$videoId';

  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = 'https://www.youtube.com/embed/$videoId?rel=0'
        ..setAttribute('style', 'border:0;width:100%;height:100%')
        ..setAttribute(
            'allow',
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen')
        ..setAttribute('allowfullscreen', '');
      return iframe;
    });
  }

  return AspectRatio(
    aspectRatio: aspectRatio,
    child: HtmlElementView(viewType: viewType),
  );
}
