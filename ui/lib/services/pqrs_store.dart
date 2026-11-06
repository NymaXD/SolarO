import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/lang.dart';
import 'auth_service.dart';
import 'pqrs_service.dart';
import 'session_store.dart';

/// Una PQRS radicada por el usuario.
class PqrsEntry {
  final String radicado;
  final String type; // petition | complaint | claim | suggestion
  final String subject;
  final DateTime createdAt;

  const PqrsEntry({
    required this.radicado,
    required this.type,
    required this.subject,
    required this.createdAt,
  });

  factory PqrsEntry.fromRemote(PqrsRemoteEntry remote) => PqrsEntry(
    radicado: remote.radicado,
    type: remote.type,
    subject: remote.subject,
    createdAt: remote.createdAt,
  );
}

/// Historial de PQRS, separado por usuario.
///
/// El servidor es la única fuente persistente del historial. Las PQRS nuevas
/// se conservan en memoria hasta que la pantalla se cierre o se actualice.
class PqrsStore extends ChangeNotifier {
  PqrsStore._();
  static final PqrsStore instance = PqrsStore._();

  static const _legacyPrefix = 'solaro.pqrs';

  final PqrsService _service = PqrsService();

  List<PqrsEntry> _entries = const [];
  bool _loaded = false;
  bool _refreshing = false;
  String? _syncError;
  int _sequence = 0;

  List<PqrsEntry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;
  bool get refreshing => _refreshing;
  String? get syncError => _syncError;

  Future<void> load() async {
    if (_loaded) {
      await refresh();
      return;
    }

    await _removeLegacyLocalHistory();
    _loaded = true;
    _syncError = null;
    notifyListeners();

    await refresh();
  }

  Future<void> _removeLegacyLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyKeys = prefs
        .getKeys()
        .where(
          (key) => key == _legacyPrefix || key.startsWith('$_legacyPrefix.'),
        )
        .toList();
    for (final key in legacyKeys) {
      await prefs.remove(key);
    }
  }

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
      _entries = remote.map(PqrsEntry.fromRemote).toList();
      _syncError = null;
    } on AuthException catch (e) {
      _syncError = e.message;
    } catch (_) {
      _syncError = tr('err_generic');
    } finally {
      _refreshing = false;
      notifyListeners();
    }
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
      subject: subject,
      createdAt: DateTime.now(),
    );
    _entries = [entry, ..._entries.where((e) => e.radicado != entry.radicado)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
}
