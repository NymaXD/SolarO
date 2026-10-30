import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_store.dart';

/// Una PQRS radicada por el usuario.
///
/// Por ahora se guarda en el dispositivo (SharedPreferences). El modelo ya
/// tiene todos los campos que necesitará el POST al backend, así que conectar
/// la API después solo requiere enviar [toJson] y actualizar el estado.
class PqrsEntry {
  final String radicado;
  final String type; // petition | complaint | claim | suggestion
  final String subject;
  final String message;
  final int rating; // 0 = sin calificación
  final DateTime createdAt;
  final String status; // submitted | synced

  const PqrsEntry({
    required this.radicado,
    required this.type,
    required this.subject,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.status = 'submitted',
  });

  Map<String, dynamic> toJson() => {
        'radicado': radicado,
        'type': type,
        'subject': subject,
        'message': message,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
        'status': status,
      };

  factory PqrsEntry.fromJson(Map<String, dynamic> json) => PqrsEntry(
        radicado: json['radicado'] as String? ?? '',
        type: json['type'] as String? ?? 'petition',
        subject: json['subject'] as String? ?? '',
        message: json['message'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        status: json['status'] as String? ?? 'submitted',
      );
}

/// Historial local de PQRS, separado por usuario.
class PqrsStore extends ChangeNotifier {
  PqrsStore._();
  static final PqrsStore instance = PqrsStore._();

  static const _prefix = 'solaro.pqrs';

  List<PqrsEntry> _entries = const [];
  bool _loaded = false;
  String _key = _prefix;

  List<PqrsEntry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;

  Future<void> load() async {
    final user = await SessionStore.readUser();
    final email = user?.email.trim().toLowerCase() ?? '';
    _key = email.isEmpty ? _prefix : '$_prefix.$email';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _entries = const [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _entries = list
            .whereType<Map<String, dynamic>>()
            .map(PqrsEntry.fromJson)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {
        _entries = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<PqrsEntry> add({
    required String type,
    required String subject,
    required String message,
    int rating = 0,
  }) async {
    if (!_loaded) await load();
    final now = DateTime.now();
    final entry = PqrsEntry(
      radicado: _nextRadicado(now),
      type: type,
      subject: subject,
      message: message,
      rating: rating,
      createdAt: now,
    );
    _entries = [entry, ..._entries];
    await _persist();
    notifyListeners();
    return entry;
  }

  String _nextRadicado(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final seq = (_entries.length + 1).toString().padLeft(4, '0');
    return 'PQRS-$y$m$d-$seq';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
