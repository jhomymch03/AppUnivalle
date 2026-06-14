# Fase D — Notificaciones (campana in-app + sonido en primer plano)

- **Fecha:** 2026-06-13
- **App:** AppUnivalle (Flutter) — rol estudiante
- **Backend:** Sistema de Titulaciones UniValle (FastAPI, `/api/v1`) — **no se toca**.
- **Principio rector:** replicar el comportamiento del web del estudiante (campana
  con badge + lista), agregando además un aviso del sistema **con sonido**
  mientras la app está en primer plano, usando solo lo que el backend ya expone.

## Contexto

Fases A/B/C completas: el menú del estudiante (8 ítems) ya está a la par del web.
Falta el subsistema de **notificaciones**, que en el web del estudiante vive en la
**campana del header** (no en el menú lateral) más una página dedicada.

El backend solo tiene notificaciones **in-app** (una tabla + endpoints de
lectura/marcado). **No existe push** (ni FCM, ni registro de token de
dispositivo). Por eso:

- Lo que SÍ hacemos de nuestro lado: campana in-app + pantalla + **notificación
  local del sistema con sonido mientras la app está corriendo**.
- Lo que NO se puede sin backend (queda fuera): push real que llegue con la app
  cerrada (FCM). Requeriría que el backend registre el token del dispositivo y
  envíe el push al crear cada notificación — fuera de alcance.

## Endpoints del backend usados (solo los que existen)

- `GET   /api/v1/notificaciones/mis?solo_no_leidas=&limit=` → lista (más recientes primero).
- `GET   /api/v1/notificaciones/contar-no-leidas` → `{ no_leidas: int }` (para el badge).
- `PATCH /api/v1/notificaciones/{id}/leer` → marca una como leída (idempotente).
- `POST  /api/v1/notificaciones/marcar-todas-leidas` → marca todas; devuelve `{ no_leidas }`.

Forma de `NotificacionOutput`: `{ id, destinatario_id, postulacion_id (nullable),
tipo, titulo, mensaje, leida, fecha_leida (nullable), created_at }`.

Tipos conocidos (de `notificaciones.ts` del web): `postulacion_enviada`,
`observacion_recibida`, `aprobada`, `rechazada`, `pausada_abandono`,
`ventana_1dia_reiniciada`, `recordatorio_ventana`. Tipo desconocido → ícono/color
de fallback (la UI no rompe).

## Decisiones de diseño (cerradas con el usuario)

1. **Superficie:** campana 🔔 con badge en la **barra superior** (AppBar) de las
   pantallas del estudiante. Al tocarla abre una **pantalla completa** de
   Notificaciones (en móvil, una pantalla es más usable que el popover del web;
   reemplaza popover + página "ver todas" en una sola).
2. **Nivel de aviso:** in-app (badge + pantalla) **+ notificación local del
   sistema con sonido mientras la app está en primer plano** (no toca backend).
   Push real con la app cerrada (FCM) queda **fuera de alcance** (necesita backend).
3. **Badge / detección:** polling cada **60 s** mientras la app está en primer
   plano (igual que el web). En la **primera carga NO se dispara** ninguna
   notificación local (evita spamear con las viejas); solo se notifican los ids
   que aparecen en sondeos posteriores.
4. **Al tocar una notificación:** se marca como leída y se navega a la
   postulación del estudiante (su postulación activa). Si el marcado falla, la
   navegación igual ocurre (el error no bloquea).

## Arquitectura (Feature-First, consistente con Fases A–C)

### Capa de datos — `lib/features/notificaciones/data/`

- `models/notificacion.dart` — modelo `Notificacion` (`id`, `postulacionId`,
  `tipo`, `titulo`, `mensaje`, `leida`, `createdAt`) + `fromJson`.
- `notificaciones_repository.dart` — `NotificacionesRepository`:
  - `Future<List<Notificacion>> listarMias({bool soloNoLeidas, int? limit})`.
  - `Future<int> contarNoLeidas()`.
  - `Future<void> marcarLeida(String id)`.
  - `Future<int> marcarTodasLeidas()`.
  - Traduce `DioException` → `ApiException`.

### Lógica pura (testeable) — `lib/features/notificaciones/application/`

- `tipo_notificacion.dart` — `({IconData icon, Color color}) estiloNotificacion(String tipo)`
  espejo del web, con fallback para tipo desconocido. (Devuelve tipos de Flutter;
  el test verifica el mapeo y el fallback.)
- `deteccion_nuevas.dart` — `Set<String> idsNuevas(Set<String> vistas, List<Notificacion> actuales)`:
  función pura que devuelve los ids presentes en `actuales` que no estaban en
  `vistas`. La usa el controller para decidir qué notificar.

### Estado — `lib/features/notificaciones/application/notificaciones_controller.dart`

`NotificacionesController extends ChangeNotifier`:
- Estado: `List<Notificacion> items`, `int noLeidas`, `bool cargando`, `String? error`.
- `Set<String> _vistas` — ids ya conocidos (para no re-notificar).
- `iniciar()` — primera carga: llena `items`, `noLeidas` y `_vistas` con lo que
  venga, **sin** disparar notificaciones locales; arranca el `Timer.periodic(60s)`.
- `detener()` — cancela el timer y limpia estado (en logout).
- `pausar()` / `reanudar()` — paran/reactivan el timer según el ciclo de vida; al
  reanudar hace un refresco inmediato.
- `refrescar()` — relee `listarMias()`; calcula `idsNuevas(_vistas, lista)`; por
  cada nueva dispara `LocalNotificacionesService.mostrar(titulo, mensaje)`;
  actualiza `_vistas`, `items`, `noLeidas`; `notifyListeners()`. Si falla, guarda
  `error` en silencio (no rompe el polling).
- `marcarLeida(id)` / `marcarTodasLeidas()` — llaman al repo y refrescan el contador.

### Notificaciones locales — `lib/features/notificaciones/application/local_notificaciones_service.dart`

Envuelve `flutter_local_notifications`:
- `init()` — inicializa el plugin, crea el canal Android (con sonido por defecto).
- `solicitarPermiso()` — pide `POST_NOTIFICATIONS` (Android 13+).
- `mostrar(String titulo, String cuerpo)` — muestra una notificación del sistema
  con sonido. Cada llamada usa un id incremental para no sobreescribir.

### Presentación — `lib/features/notificaciones/presentation/`

- `notifications_bell.dart` — `NotificationsBell`: acción de AppBar. Observa
  `NotificacionesController.noLeidas` → ícono de campana con badge ("9+" si >9).
  `onTap` → `context.push('/notificaciones')`.
- `notificaciones_screen.dart` — `NotificacionesScreen`: lista desde el
  controller (ícono+color por tipo, título, mensaje, fecha relativa, punto si no
  leída), pull-to-refresh, botón "Marcar todas como leídas" en la AppBar (si hay
  no leídas), estado vacío y estado de error con reintento. Al tocar una: marca
  leída + navega a la postulación activa (`/postulacion/nueva`, que muestra la
  activa). Usa `fechaRelativa` de `core/utils/formato.dart` (ya existe).

### Wiring

- `pubspec.yaml` — agrega `flutter_local_notifications`.
- `AndroidManifest.xml` — permiso `POST_NOTIFICATIONS`.
- `AppDependencies` — registra `NotificacionesRepository`.
- `main.dart` — inicializa `LocalNotificacionesService` y pide permiso; crea el
  `NotificacionesController` (con el repo + el servicio local).
- `app.dart` — provee `NotificacionesController` por Provider; observa el ciclo
  de vida (`WidgetsBindingObserver`) para `pausar()`/`reanudar()` el polling.
- `SessionController` ya define los estados; el arranque/detención del controller
  de notificaciones se dispara desde `app.dart` reaccionando a
  `SessionStatus.autenticado` (iniciar) y a la salida de ese estado (detener).
- `NotificationsBell` se agrega a las `actions` de las AppBars de las pantallas
  del estudiante (Home, Mis Postulaciones, Detalle, Observaciones, Historial,
  Documentos, Carta de Respuesta, Perfil, formulario).
- `router.dart` — ruta `/notificaciones`.

## Manejo de errores

- Todas las llamadas pasan por Dio → `ApiException` con el `detail` del backend.
- El **polling** falla en silencio (guarda `error` pero no interrumpe el timer ni
  molesta al usuario).
- La **pantalla** muestra error con botón de reintento; acciones de marcado
  muestran un SnackBar si fallan.

## Tests

- `Notificacion.fromJson` — parseo (incluyendo `postulacion_id` null).
- `estiloNotificacion(tipo)` — mapeo de un tipo conocido y **fallback** para tipo
  desconocido.
- `idsNuevas(vistas, actuales)` — detecta solo los ids no vistos; vacío si no hay
  nuevos.

## Fuera de alcance

- **Push real (FCM)** con la app cerrada: requiere backend (registro de token +
  envío al crear la notificación). Documentado como pendiente para coordinar con
  el equipo del backend; no se implementa aquí.
- Notificaciones para roles que no sean estudiante (la app es solo para
  estudiantes).
- Trabajo en segundo plano garantizado (WorkManager/foreground service): el
  sondeo es solo en primer plano, según lo acordado.

## Criterios de aceptación

1. Aparece la campana con badge en la barra superior; el número refleja las no
   leídas y se actualiza tras leer / marcar todas.
2. Tocar la campana abre la pantalla con la lista; pull-to-refresh recarga.
3. "Marcar todas como leídas" pone el badge en 0 y quita los puntos de no leída.
4. Tocar una notificación la marca leída y navega a la postulación.
5. Con la app abierta, al llegar una notificación nueva (detectada en un sondeo)
   suena y aparece un aviso del sistema; las que ya existían al abrir la app NO
   disparan aviso.
6. `flutter analyze` sin errores; `flutter test` en verde (incluye los 3 tests
   nuevos).
