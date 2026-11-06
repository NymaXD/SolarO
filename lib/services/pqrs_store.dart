import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/lang.dart';
import 'auth_service.dart';
import 'pqrs_service.dart';
import 'session_store.dart';

/// Una PQRS radicada por el usuario.
///
/// El historial local se conserva como caché de detalles (nombre, correo,
/// descripción y calificación), porque `GET /pqrs` solo devuelve el radicado,
/// el tipo, el asunto y la fecha. Al cargar, ambos historiales se fusionan.
class PqrsEntry {
  final String radicado;
  final String type; // petition | complaint | claim | suggestion
  final String name;
  final String email;
  final String subject;
  final String message;
  final int rating; // 0 = sin calificación
  final DateTime createdAt;
  final String status; // submitted | synced

  const PqrsEntry({
    required this.radicado,
    required this.type,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.status = 'submitted',
  });

  Map<String, dynamic> toJson() => {
        'radicado': radicado,
        'type': type,
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
        'status': status,
      };

  factory PqrsEntry.fromJson(Map<String, dynamic> json) => PqrsEntry(
        radicado: json['radicado'] as String? ?? '',
        type: json['type'] as String? ?? 'petition',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        message: json['message'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        status: json['status'] as String? ?? 'submitted',
      );

  /// Entrada que solo existe en el servidor (radicada desde otro dispositivo).
  factory PqrsEntry.fromRemote(PqrsRemoteEntry remote) => PqrsEntry(
        radicado: remote.radicado,
        type: remote.type,
        name: '',
        email: '',
        subject: remote.subject,
        message: '',
        rating: 0,
        createdAt: remote.createdAt,
        status: 'synced',
      );

  PqrsEntry copyWith({String? status}) => PqrsEntry(
        radicado: radicado,
        type: type,
        name: name,
        email: email,
        subject: subject,
        message: message,
        rating: rating,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}

/// Historial de PQRS, separado por usuario.
///
/// `POST /pqrs` es la fuente de verdad; el historial local solo guarda los
/// detalles que la API no devuelve. Si el envío falla, no se guarda nada y el
/// error se propaga a la pantalla.
class PqrsStore extends ChangeNotifier {
  PqrsStore._();
  static final PqrsStore instance = PqrsStore._();

  static const _prefix = 'solaro.pqrs';

  final PqrsService _service = PqrsService();

  List<PqrsEntry> _entries = const [];
  bool _loaded = false;
  bool _refreshing = false;
  String? _syncError;
  String _key = _prefix;
  int _sequence = 0;

  List<PqrsEntry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;
  bool get refreshing => _refreshing;
  String? get syncError => _syncError;

  Future<void> load() async {
    final user = await SessionStore.readUser();
    final email = user?.email.trim().toLowerCase() ?? '';
    final key = email.isEmpty ? _prefix : '$_prefix.$email';

    // Si ya está cargado el mismo usuario, solo se refresca el servidor.
    if (_loaded && key == _key) {
      await refresh();
      return;
    }

    _key = key;
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
    _syncError = null;
    notifyListeners();

    await refresh();
  }

  /// Trae las PQRS del backend y las fusiona con la caché local.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final token = await SessionStore.validToken();
      if (token == null) {
        _syncError = tr('session_expired');
        return;
      }
      final remote = await _service.list(token);
      _merge(remote);
      _syncError = null;
      await _persist();
    } on AuthException catch (e) {
      _syncError = e.message;
    } catch (_) {
      _syncError = tr('err_generic');
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void _merge(List<PqrsRemoteEntry> remote) {
    final byRadicado = {for (final entry in _entries) entry.radicado: entry};
    for (final item in remote) {
      final local = byRadicado[item.radicado];
      byRadicado[item.radicado] =
          local == null ? PqrsEntry.fromRemote(item) : local.copyWith(status: 'synced');
    }
    _entries = byRadicado.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<PqrsEntry> add({
    required String type,
    required String name,
    required String email,
    required String subject,
    required String message,
    int rating = 0,
  }) async {
    if (!_loaded) await load();

    final token = await SessionStore.validToken();
    if (token == null) {
      throw AuthException(tr('session_expired'), 401);
    }

    var radicado = _nextRadicado();
    try {
      await _service.submit(
        token,
        radicado: radicado,
        type: type,
        name: name,
        email: email,
        subject: subject,
        message: message,
        rating: rating,
      );
    } on AuthException catch (e) {
      // El radicado es generado por el cliente: si ya existe, se reintenta una
      // vez con uno nuevo.
      if (e.statusCode != 409) rethrow;
      radicado = _nextRadicado();
      await _service.submit(
        token,
        radicado: radicado,
        type: type,
        name: name,
        email: email,
        subject: subject,
        message: message,
        rating: rating,
      );
    }

    final entry = PqrsEntry(
      radicado: radicado,
      type: type,
      name: name,
      email: email,
      subject: subject,
      message: message,
      rating: rating,
      createdAt: DateTime.now(),
      status: 'synced',
    );
    _entries = [
      entry,
      ..._entries.where((e) => e.radicado != entry.radicado),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
    notifyListeners();
    return entry;
  }

  /// Formato `PQRS-AAAAMMDD-HHMMSSmmmNNN`, válido para el backend (letras,
  /// números y guiones) y único incluso si se radican dos seguidas.
  String _nextRadicado() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    _sequence = (_sequence + 1) % 1000;
    final seq = _sequence.toString().padLeft(3, '0');
    return 'PQRS-$y$m$d-$hh$mm$ss$ms$seq';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
