// lib/features/notificaciones/application/notificaciones_controller.dart
/// Estado compartido de notificaciones (Provider). Hace polling cada 60 s en
/// primer plano, detecta notificaciones nuevas y dispara un aviso local con
/// sonido. En la primera carga NO avisa (evita spamear con las viejas).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/notificacion.dart';
import '../data/notificaciones_repository.dart';
import 'deteccion_nuevas.dart';
import 'local_notificaciones_service.dart';

class NotificacionesController extends ChangeNotifier {
  NotificacionesController({
    required NotificacionesRepository repo,
    required LocalNotificacionesService local,
  })  : _repo = repo,
        _local = local;

  final NotificacionesRepository _repo;
  final LocalNotificacionesService _local;

  static const _intervalo = Duration(seconds: 60);

  List<Notificacion> _items = const [];
  int _noLeidas = 0;
  bool _cargando = false;
  String? _error;

  final Set<String> _vistas = {};
  bool _activo = false;
  Timer? _timer;

  List<Notificacion> get items => _items;
  int get noLeidas => _noLeidas;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Primera carga + arranque del polling. Idempotente. NO dispara avisos.
  Future<void> iniciar() async {
    if (_activo) return;
    _activo = true;
    _cargando = true;
    notifyListeners();
    try {
      final lista = await _repo.listarMias();
      _items = lista;
      _vistas
        ..clear()
        ..addAll(lista.map((n) => n.id));
      _noLeidas = lista.where((n) => !n.leida).length;
      _error = null;
    } on Object catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
    _timer = Timer.periodic(_intervalo, (_) => refrescar());
  }

  /// Detiene y limpia (logout).
  void detener() {
    _timer?.cancel();
    _timer = null;
    _activo = false;
    _items = const [];
    _noLeidas = 0;
    _vistas.clear();
    _error = null;
    notifyListeners();
  }

  /// Pausa el polling (app a segundo plano).
  void pausar() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reanuda el polling (app a primer plano) con un refresco inmediato.
  void reanudar() {
    if (!_activo) return;
    refrescar();
    _timer ??= Timer.periodic(_intervalo, (_) => refrescar());
  }

  /// Relee la lista; avisa (sonido) por cada notificación nueva.
  Future<void> refrescar() async {
    try {
      final lista = await _repo.listarMias();
      final nuevas = idsNuevas(_vistas, lista);
      for (final n in lista.where((n) => nuevas.contains(n.id))) {
        await _local.mostrar(n.titulo, n.mensaje);
      }
      _items = lista;
      _vistas
        ..clear()
        ..addAll(lista.map((n) => n.id));
      _noLeidas = lista.where((n) => !n.leida).length;
      _error = null;
      notifyListeners();
    } on Object catch (e) {
      // El polling falla en silencio; guardamos el error por si la pantalla lo usa.
      _error = e.toString();
    }
  }

  Future<void> marcarLeida(String id) async {
    await _repo.marcarLeida(id);
    await refrescar();
  }

  Future<void> marcarTodasLeidas() async {
    await _repo.marcarTodasLeidas();
    await refrescar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
