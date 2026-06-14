# Fase C — Tanda 2 (Documentos + Carta de Respuesta + Perfil) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completar la paridad del menú del estudiante con el web implementando las 3 pantallas restantes — Documentos (con descarga real), Carta de Respuesta (resolución; descarga deshabilitada como el web) y Perfil (datos + editar + cambiar contraseña).

**Architecture:** Feature-First sobre el `ApiClient`/Dio existente, igual que la Tanda 1. La lógica testeable (qué documentos tiene una postulación, el mapeo estado→resolución, el parseo de carrera) vive en funciones/clases puras con tests unitarios; los repositorios solo hacen HTTP. Las pantallas se agregan al Drawer ya existente activando sus 3 ítems.

**Tech Stack:** Flutter, Dio 5.7, provider 6.1, go_router 14.6, file_picker, url_launcher (nuevo, para abrir PDFs por URL firmada). Tests con flutter_test.

> **Solo se usa lo que el backend YA expone.** Descarga de archivos: `GET /archivos/{id}` (URL firmada) — existe. Carrera: `GET /carreras/{id}` — existe. Perfil: `PATCH /auth/me` + `POST /auth/cambiar-password` — existen. La descarga del PDF de la **carta de respuesta** NO existe en el backend (pendiente R3): el botón queda **deshabilitado**, igual que el web. No se inventa ni se toca el backend.

> **Sin git:** este proyecto no es repositorio git. Cada tarea termina con un checkpoint de `analyze`/`test` en vez de commit. `flutter analyze` exit code != 0 ante cualquier `info`; los ~8 `prefer_initializing_formals` ya existentes son aceptables — solo importan errores/warnings o infos nuevos no intencionales.

---

## Estructura de archivos

**Crear:**
- `lib/features/archivos/application/documentos_postulacion.dart` — helper puro `documentosDePostulacion(...)`.
- `lib/features/postulaciones/application/resolucion_carta.dart` — `ResolucionCarta` + `resolucionDeCarta(...)`.
- `lib/features/catalogos/data/models/carrera.dart` — modelo `Carrera`.
- `lib/features/catalogos/data/carreras_repository.dart` — `obtener(id)`.
- `lib/features/postulaciones/presentation/documentos_screen.dart` — pantalla Documentos.
- `lib/features/postulaciones/presentation/carta_respuesta_screen.dart` — pantalla Carta de Respuesta.
- `lib/features/perfil/presentation/perfil_screen.dart` — pantalla Perfil.
- `test/documentos_postulacion_test.dart`, `test/resolucion_carta_test.dart`, `test/carrera_test.dart`.

**Modificar:**
- `pubspec.yaml` — agrega `url_launcher`.
- `android/app/src/main/AndroidManifest.xml` — agrega `<queries>` para abrir URLs (url_launcher en Android 11+).
- `lib/features/postulaciones/data/models/postulacion.dart` — agrega `carreraId`, `fechaAprobacionFinal`, `fechaRechazo` (nullables).
- `lib/features/archivos/data/archivos_repository.dart` — agrega `obtener(id)`.
- `lib/features/auth/data/auth_repository.dart` — agrega `actualizarPerfil(...)`.
- `lib/features/auth/application/session_controller.dart` — agrega `actualizarUsuarioLocal(...)`.
- `lib/core/di/app_dependencies.dart` — registra `CarrerasRepository`.
- `lib/features/shell/presentation/app_drawer.dart` — activa Documentos/Carta/Perfil (quita `habilitado: false`).
- `lib/app/router.dart` — agrega rutas `/documentos`, `/carta-respuesta`, `/perfil`.

---

## Task 1: Dependencia url_launcher + queries de Android

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Agregar el paquete**

En `pubspec.yaml`, dentro de `dependencies:`, debajo de `file_picker: ^8.1.2`, agrega:

```yaml
  url_launcher: ^6.3.0          # abrir PDFs (URL firmada) en visor externo
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: "Got dependencies!".

- [ ] **Step 3: Agregar el bloque `<queries>` en AndroidManifest**

Abre `android/app/src/main/AndroidManifest.xml`. Como **hijo directo de `<manifest>`** (hermano de `<application>`, normalmente justo antes de `<application ...>`), agrega:

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
```

(Esto permite que `url_launcher` resuelva un navegador/visor para abrir la URL firmada en Android 11+.)

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze`
Expected: sin errores nuevos (solo los `info` conocidos).

---

## Task 2: Ampliar Postulacion con carreraId y fechas de resolución

**Files:**
- Modify: `lib/features/postulaciones/data/models/postulacion.dart`

- [ ] **Step 1: Agregar los campos (nullables, para no romper fixtures de test)**

En el constructor, junto a los opcionales, agrega `this.carreraId,`, `this.fechaAprobacionFinal,` y `this.fechaRechazo,`.

En la declaración de campos agrega:

```dart
  final String? carreraId;
  final DateTime? fechaAprobacionFinal;
  final DateTime? fechaRechazo;
```

- [ ] **Step 2: Mapear en fromJson**

Dentro de `Postulacion.fromJson`, antes de `createdAt:`, agrega:

```dart
      carreraId: json['carrera_id'] as String?,
      fechaAprobacionFinal: (json['fecha_aprobacion_final'] as String?) != null
          ? DateTime.parse(json['fecha_aprobacion_final'] as String)
          : null,
      fechaRechazo: (json['fecha_rechazo'] as String?) != null
          ? DateTime.parse(json['fecha_rechazo'] as String)
          : null,
```

- [ ] **Step 3: Checkpoint**

Run: `flutter test test/postulacion_model_test.dart test/postulacion_actual_test.dart`
Expected: PASS (los campos nuevos son opcionales; los fixtures existentes siguen válidos).

---

## Task 3: Documentos de una postulación — helper (TDD) + obtener(id) en ArchivosRepository

**Files:**
- Create: `lib/features/archivos/application/documentos_postulacion.dart`
- Test: `test/documentos_postulacion_test.dart`
- Modify: `lib/features/archivos/data/archivos_repository.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/documentos_postulacion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion.dart';
import 'package:appunivalle/features/archivos/application/documentos_postulacion.dart';

Postulacion _p(Map<String, dynamic> extra) => Postulacion.fromJson({
      'id': 'p1',
      'titulo': 'T',
      'descripcion': 'Descripcion larga.',
      'modalidad': 'Tesis',
      'tipo_tutor': 'externo',
      'estado_actual': 'BORRADOR',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      ...extra,
    });

void main() {
  test('lista solo los documentos presentes con su etiqueta', () {
    final p = _p({
      'tutor_externo_cv_archivo_id': 'cv-1',
      'tutor_externo_titulo_archivo_id': null,
      'carta_postulacion_archivo_id': null,
    });
    final docs = documentosDePostulacion(p);
    expect(docs, hasLength(1));
    expect(docs.first.archivoId, 'cv-1');
    expect(docs.first.label, 'CV del tutor');
  });

  test('sin documentos -> lista vacia', () {
    expect(documentosDePostulacion(_p(const {})), isEmpty);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/documentos_postulacion_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el helper**

```dart
// lib/features/archivos/application/documentos_postulacion.dart
/// Devuelve los documentos descargables presentes en una postulacion, con su
/// etiqueta para mostrar. Espeja `DocumentosExpediente.vue` del web: carta de
/// postulacion (si existe) y, para tutor externo, su CV y titulo.
library;

import '../../postulaciones/data/models/postulacion.dart';

/// Un documento descargable: etiqueta + id de archivo (para pedir la URL).
typedef DocumentoItem = ({String label, String archivoId});

List<DocumentoItem> documentosDePostulacion(Postulacion p) {
  final docs = <DocumentoItem>[];
  if (p.cartaPostulacionArchivoId != null) {
    docs.add((label: 'Carta de postulación', archivoId: p.cartaPostulacionArchivoId!));
  }
  if (p.tutorExternoCvArchivoId != null) {
    docs.add((label: 'CV del tutor', archivoId: p.tutorExternoCvArchivoId!));
  }
  if (p.tutorExternoTituloArchivoId != null) {
    docs.add((label: 'Título académico del tutor', archivoId: p.tutorExternoTituloArchivoId!));
  }
  return docs;
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/documentos_postulacion_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Agregar obtener(id) al ArchivosRepository**

En `lib/features/archivos/data/archivos_repository.dart`, dentro de la clase (después de `subir(...)`), agrega:

```dart
  /// Metadata + URL firmada de un archivo (`GET /archivos/{id}`).
  Future<ArchivoSubido> obtener(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/archivos/$id');
      return ArchivoSubido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
```

- [ ] **Step 6: Checkpoint**

Run: `flutter analyze lib/features/archivos`
Expected: sin errores.

---

## Task 4: DocumentosScreen

**Files:**
- Create: `lib/features/postulaciones/presentation/documentos_screen.dart`

- [ ] **Step 1: Crear la pantalla**

```dart
// lib/features/postulaciones/presentation/documentos_screen.dart
/// Pantalla "Documentos": archivos descargables de la postulacion activa.
/// Cada item pide su URL firmada (`GET /archivos/{id}`) y la abre en el visor
/// externo (url_launcher). Espeja `estudiante/Documentos.vue` del web.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../archivos/application/documentos_postulacion.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  late Future<Postulacion?> _carga;
  String? _abriendoId;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<Postulacion?> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    return pickActiva(lista);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrir(DocumentoItem doc) async {
    setState(() => _abriendoId = doc.archivoId);
    final repo = context.read<AppDependencies>().archivosRepository;
    try {
      final archivo = await repo.obtener(doc.archivoId);
      final ok = await launchUrl(
        Uri.parse(archivo.url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _snack('No se pudo abrir el documento.');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _abriendoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Documentos')),
      body: FutureBuilder<Postulacion?>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudieron cargar los documentos.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final activa = snapshot.data;
          if (activa == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Todavía no tienes una postulación activa.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/postulacion/nueva'),
                    child: const Text('Ir a Nueva postulación'),
                  ),
                ],
              ),
            );
          }
          final docs = documentosDePostulacion(activa);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(activa.titulo,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  EstadoBadge(estado: activa.estado),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No hay documentos en tu expediente todavía.'),
                  ),
                )
              else
                for (final doc in docs)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(doc.label),
                      trailing: _abriendoId == doc.archivoId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new),
                      onTap:
                          _abriendoId == null ? () => _abrir(doc) : null,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/documentos_screen.dart`
Expected: sin errores. (Si aparece `use_build_context_synchronously`, ya está mitigado: `repo` se captura antes del `await` y `_snack` tiene guarda `mounted`.)

---

## Task 5: Resolución de carta (TDD) + CartaRespuestaScreen

**Files:**
- Create: `lib/features/postulaciones/application/resolucion_carta.dart`
- Create: `lib/features/postulaciones/presentation/carta_respuesta_screen.dart`
- Test: `test/resolucion_carta_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/resolucion_carta_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/estado_postulacion.dart';
import 'package:appunivalle/features/postulaciones/application/resolucion_carta.dart';

void main() {
  test('aprobado / rechazado / observado tienen resolucion', () {
    expect(resolucionDeCarta(EstadoPostulacion.aprobado)?.tipo,
        TipoResolucion.aprobado);
    expect(resolucionDeCarta(EstadoPostulacion.rechazado)?.tipo,
        TipoResolucion.rechazado);
    expect(resolucionDeCarta(EstadoPostulacion.observadoSecretaria)?.tipo,
        TipoResolucion.observado);
    expect(resolucionDeCarta(EstadoPostulacion.observadoDireccion)?.tipo,
        TipoResolucion.observado);
  });

  test('estados sin resolucion devuelven null', () {
    expect(resolucionDeCarta(EstadoPostulacion.borrador), isNull);
    expect(resolucionDeCarta(EstadoPostulacion.enviadoASecretaria), isNull);
    expect(resolucionDeCarta(EstadoPostulacion.enRevisionDireccionCat), isNull);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/resolucion_carta_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el helper**

```dart
// lib/features/postulaciones/application/resolucion_carta.dart
/// Mapea el estado de la postulacion a la "resolucion" mostrada en Carta de
/// Respuesta (espeja `CartaRespuesta.vue` del web). La fecha concreta la elige
/// la UI segun el tipo; aqui solo va el texto y el tipo (para icono/color).
library;

import '../data/models/estado_postulacion.dart';

enum TipoResolucion { aprobado, rechazado, observado }

class ResolucionCarta {
  const ResolucionCarta({
    required this.tipo,
    required this.titulo,
    required this.proximoPaso,
  });

  final TipoResolucion tipo;
  final String titulo;
  final String proximoPaso;
}

/// `null` si el estado todavia no tiene una resolucion que mostrar.
ResolucionCarta? resolucionDeCarta(EstadoPostulacion estado) {
  switch (estado) {
    case EstadoPostulacion.aprobado:
      return const ResolucionCarta(
        tipo: TipoResolucion.aprobado,
        titulo: 'Propuesta aprobada',
        proximoPaso: 'Continuar al Módulo 2.',
      );
    case EstadoPostulacion.rechazado:
      return const ResolucionCarta(
        tipo: TipoResolucion.rechazado,
        titulo: 'Propuesta rechazada',
        proximoPaso: 'Generar una nueva postulación.',
      );
    case EstadoPostulacion.observadoSecretaria:
    case EstadoPostulacion.observadoDireccion:
      return const ResolucionCarta(
        tipo: TipoResolucion.observado,
        titulo: 'Propuesta observada',
        proximoPaso: 'Corregir y reenviar el expediente.',
      );
    case EstadoPostulacion.borrador:
    case EstadoPostulacion.enviadoASecretaria:
    case EstadoPostulacion.enRevisionDireccionCat:
    case EstadoPostulacion.pausadoPorAbandono:
      return null;
  }
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/resolucion_carta_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Crear la pantalla CartaRespuestaScreen**

```dart
// lib/features/postulaciones/presentation/carta_respuesta_screen.dart
/// Pantalla "Carta de Respuesta": resolucion de la postulacion activa (estado,
/// motivo, fecha, proximo paso). La descarga del PDF de la carta NO existe en
/// el backend (R3 pendiente): el boton queda deshabilitado, igual que el web.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formato.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../application/resolucion_carta.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';

class CartaRespuestaScreen extends StatefulWidget {
  const CartaRespuestaScreen({super.key});

  @override
  State<CartaRespuestaScreen> createState() => _CartaRespuestaScreenState();
}

class _CartaRespuestaScreenState extends State<CartaRespuestaScreen> {
  late Future<Postulacion?> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<Postulacion?> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    return pickActiva(lista);
  }

  ({IconData icon, Color color}) _estilo(TipoResolucion t) {
    switch (t) {
      case TipoResolucion.aprobado:
        return (icon: Icons.check_circle, color: Colors.green);
      case TipoResolucion.rechazado:
        return (icon: Icons.cancel, color: Colors.red);
      case TipoResolucion.observado:
        return (icon: Icons.comment, color: Colors.amber);
    }
  }

  DateTime? _fecha(Postulacion p, TipoResolucion t) {
    switch (t) {
      case TipoResolucion.aprobado:
        return p.fechaAprobacionFinal;
      case TipoResolucion.rechazado:
        return p.fechaRechazo;
      case TipoResolucion.observado:
        return p.updatedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Carta de Respuesta')),
      body: FutureBuilder<Postulacion?>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudo cargar la resolución.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final activa = snapshot.data;
          final resolucion =
              activa == null ? null : resolucionDeCarta(activa.estado);

          if (activa == null || resolucion == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tu postulación todavía no tiene una resolución. '
                  'Te avisaremos cuando haya novedades.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final estilo = _estilo(resolucion.tipo);
          final fecha = _fecha(activa, resolucion.tipo);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(estilo.icon, color: estilo.color, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(resolucion.titulo,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                          EstadoBadge(estado: activa.estado),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('FECHA DE RESOLUCIÓN',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(fecha != null ? formatFecha(fecha) : '—'),
                      if (activa.motivoRechazo != null &&
                          activa.motivoRechazo!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('MOTIVO',
                            style: Theme.of(context).textTheme.labelSmall),
                        Text(activa.motivoRechazo!),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Próximo paso: ${resolucion.proximoPaso}'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: null, // R3 pendiente en backend, como el web
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar carta (no disponible aún)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 6: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/carta_respuesta_screen.dart`
Expected: sin errores.

---

## Task 6: Carrera (modelo TDD) + CarrerasRepository + registro en DI

**Files:**
- Create: `lib/features/catalogos/data/models/carrera.dart`
- Create: `lib/features/catalogos/data/carreras_repository.dart`
- Test: `test/carrera_test.dart`
- Modify: `lib/core/di/app_dependencies.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/carrera_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/models/carrera.dart';

void main() {
  test('Carrera.fromJson mapea campos', () {
    final c = Carrera.fromJson({
      'id': 'c1',
      'codigo': 'INF',
      'nombre': 'Ingeniería de Sistemas',
      'facultad': 'Tecnología',
      'activa': true,
    });
    expect(c.codigo, 'INF');
    expect(c.nombre, 'Ingeniería de Sistemas');
    expect(c.facultad, 'Tecnología');
  });

  test('facultad puede ser null', () {
    final c = Carrera.fromJson({
      'id': 'c2',
      'codigo': 'MAT',
      'nombre': 'Matemática',
      'facultad': null,
      'activa': true,
    });
    expect(c.facultad, isNull);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/carrera_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el modelo**

```dart
// lib/features/catalogos/data/models/carrera.dart
/// Carrera — espeja `CarreraOutput` (solo los campos que la app muestra).
library;

class Carrera {
  const Carrera({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.facultad,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String? facultad;

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      facultad: json['facultad'] as String?,
    );
  }
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/carrera_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Crear el repositorio**

```dart
// lib/features/catalogos/data/carreras_repository.dart
/// Repositorio de carreras. Solo lectura del detalle (`GET /carreras/{id}`),
/// que cualquier autenticado puede consultar. Lo usa Perfil para mostrar la
/// carrera derivada de la postulacion activa del estudiante.
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/carrera.dart';

class CarrerasRepository {
  CarrerasRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Carrera> obtener(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/carreras/$id');
      return Carrera.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
```

- [ ] **Step 6: Registrar en AppDependencies**

En `lib/core/di/app_dependencies.dart`:

Import (junto a los otros de catalogos):

```dart
import '../../features/catalogos/data/carreras_repository.dart';
```

Campo (después de `final ModalidadesRepository modalidadesRepository;`):

```dart
  final CarrerasRepository carrerasRepository;
```

Parámetro del constructor privado (después de `required this.modalidadesRepository,`):

```dart
    required this.carrerasRepository,
```

En `create()`, después de crear `modalidadesRepository`:

```dart
    final carrerasRepository = CarrerasRepository(dio: apiClient.dio);
```

En el `return AppDependencies._(...)`, después de `modalidadesRepository: modalidadesRepository,`:

```dart
      carrerasRepository: carrerasRepository,
```

- [ ] **Step 7: Checkpoint**

Run: `flutter analyze lib/features/catalogos lib/core/di/app_dependencies.dart`
Expected: sin errores.

---

## Task 7: actualizarPerfil en AuthRepository + actualizarUsuarioLocal en SessionController

**Files:**
- Modify: `lib/features/auth/data/auth_repository.dart`
- Modify: `lib/features/auth/application/session_controller.dart`

- [ ] **Step 1: Agregar actualizarPerfil al AuthRepository**

En `auth_repository.dart`, después de `obtenerPerfil()` (antes de `cambiarPassword`), agrega:

```dart
  /// Actualiza nombres/apellidos/telefono del propio usuario (`PATCH /auth/me`).
  /// Devuelve el perfil actualizado. Envia los tres campos (como el web).
  Future<UsuarioMe> actualizarPerfil({
    required String nombres,
    required String apellidos,
    String? telefono,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {
          'nombres': nombres,
          'apellidos': apellidos,
          'telefono': telefono,
        },
      );
      return UsuarioMe.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
```

- [ ] **Step 2: Agregar actualizarUsuarioLocal al SessionController**

En `session_controller.dart`, después de `volverALogin()`, agrega:

```dart
  /// Refresca en memoria el usuario tras editar el perfil (PATCH /auth/me).
  /// No cambia el [SessionStatus]; solo actualiza los datos visibles.
  void actualizarUsuarioLocal(UsuarioMe usuario) {
    _usuario = usuario;
    notifyListeners();
  }
```

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze lib/features/auth`
Expected: sin errores (salvo los `prefer_initializing_formals` ya conocidos).

---

## Task 8: PerfilScreen (datos + editar + cambiar contraseña)

**Files:**
- Create: `lib/features/perfil/presentation/perfil_screen.dart`

- [ ] **Step 1: Crear la pantalla**

```dart
// lib/features/perfil/presentation/perfil_screen.dart
/// Pantalla "Perfil / Mi cuenta": datos de /auth/me, carrera derivada de la
/// postulacion activa, y acciones self-service (editar datos via PATCH /auth/me,
/// cambiar contraseña via POST /auth/cambiar-password). Espeja
/// `estudiante/Perfil.vue` + `PerfilSelfService.vue` del web.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/session_controller.dart';
import '../../catalogos/data/models/carrera.dart';
import '../../shell/presentation/app_drawer.dart';
import '../../postulaciones/application/postulacion_actual.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<Carrera?> _carrera;

  @override
  void initState() {
    super.initState();
    _carrera = _cargarCarrera();
  }

  Future<Carrera?> _cargarCarrera() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final activa = pickActiva(lista);
    final id = activa?.carreraId;
    if (id == null) return null;
    return deps.carrerasRepository.obtener(id);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        usuario.nombres.isNotEmpty ? usuario.nombres[0] : '?',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(usuario.nombreCompleto,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _campo(context, 'Correo', usuario.email),
                _campo(context, 'Teléfono', usuario.telefono ?? '—'),
                FutureBuilder<Carrera?>(
                  future: _carrera,
                  builder: (context, snapshot) {
                    final c = snapshot.data;
                    final valor = c != null
                        ? '${c.nombre} (${c.codigo})'
                        : 'No disponible hasta tener una postulación.';
                    return Column(
                      children: [
                        _campo(context, 'Carrera', valor),
                        if (c?.facultad != null)
                          _campo(context, 'Facultad', c!.facultad!),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _editarDatos(usuario.nombres,
                      usuario.apellidos, usuario.telefono),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar datos'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _cambiarPassword,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Cambiar contraseña'),
                ),
              ],
            ),
    );
  }

  Widget _campo(BuildContext context, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(valor),
        ],
      ),
    );
  }

  Future<void> _editarDatos(
      String nombres, String apellidos, String? telefono) async {
    final nombresCtl = TextEditingController(text: nombres);
    final apellidosCtl = TextEditingController(text: apellidos);
    final telefonoCtl = TextEditingController(text: telefono ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar datos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombresCtl,
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
              TextField(
                controller: apellidosCtl,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              TextField(
                controller: telefonoCtl,
                decoration:
                    const InputDecoration(labelText: 'Teléfono (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (guardar != true) return;
    if (nombresCtl.text.trim().length < 2 ||
        apellidosCtl.text.trim().length < 2) {
      _snack('Nombres y apellidos deben tener al menos 2 caracteres.');
      return;
    }

    final deps = context.read<AppDependencies>();
    final session = context.read<SessionController>();
    try {
      final actualizado = await deps.authRepository.actualizarPerfil(
        nombres: nombresCtl.text.trim(),
        apellidos: apellidosCtl.text.trim(),
        telefono: telefonoCtl.text.trim().isEmpty
            ? null
            : telefonoCtl.text.trim(),
      );
      session.actualizarUsuarioLocal(actualizado);
      _snack('Perfil actualizado.');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _cambiarPassword() async {
    final actualCtl = TextEditingController();
    final nuevaCtl = TextEditingController();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actualCtl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Contraseña actual'),
              ),
              TextField(
                controller: nuevaCtl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Nueva contraseña (mín. 6)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cambiar')),
        ],
      ),
    );

    if (guardar != true) return;
    if (nuevaCtl.text.length < 6) {
      _snack('La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }

    final deps = context.read<AppDependencies>();
    try {
      await deps.authRepository.cambiarPassword(
        passwordActual: actualCtl.text,
        passwordNueva: nuevaCtl.text,
      );
      _snack('Contraseña cambiada.');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/perfil/presentation/perfil_screen.dart`
Expected: sin errores. Si aparece `use_build_context_synchronously` en `_editarDatos`/`_cambiarPassword` tras el `showDialog`, captura `deps`/`session` con `context.read(...)` ANTES de continuar el flujo async post-dialog, o agrega `if (!mounted) return;` tras el `await showDialog`. Mantén el comportamiento.

---

## Task 9: Activar los 3 ítems del Drawer + rutas

**Files:**
- Modify: `lib/features/shell/presentation/app_drawer.dart`
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Activar los ítems en el Drawer**

En `app_drawer.dart`, en la lista `_items`, quita `habilitado: false` de los tres ítems para que queden habilitados:

```dart
  _Item('Documentos', Icons.insert_drive_file_outlined, '/documentos'),
  ...
  _Item('Carta de Respuesta', Icons.mail_outline, '/carta-respuesta'),
  _Item('Perfil', Icons.person_outline, '/perfil'),
```

(El resto del archivo no cambia: la lógica de `habilitado` ya soporta ambos casos.)

- [ ] **Step 2: Importar las pantallas en el router**

En `lib/app/router.dart`, junto a los imports de pantallas, agrega:

```dart
import '../features/postulaciones/presentation/documentos_screen.dart';
import '../features/postulaciones/presentation/carta_respuesta_screen.dart';
import '../features/perfil/presentation/perfil_screen.dart';
```

- [ ] **Step 3: Agregar constantes y rutas**

En `abstract final class Rutas`, después de `static const historial = '/historial';` agrega:

```dart
  static const documentos = '/documentos';
  static const cartaRespuesta = '/carta-respuesta';
  static const perfil = '/perfil';
```

En la lista `routes:`, después de la ruta `Rutas.historial`, agrega:

```dart
      GoRoute(
        path: Rutas.documentos,
        builder: (_, _) => const DocumentosScreen(),
      ),
      GoRoute(
        path: Rutas.cartaRespuesta,
        builder: (_, _) => const CartaRespuestaScreen(),
      ),
      GoRoute(
        path: Rutas.perfil,
        builder: (_, _) => const PerfilScreen(),
      ),
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze lib/app/router.dart lib/features/shell/presentation/app_drawer.dart`
Expected: sin errores.

---

## Task 10: Verificación final

**Files:** —

- [ ] **Step 1: Análisis estático completo**

Run: `flutter analyze`
Expected: solo los `info - prefer_initializing_formals` conocidos (su número crece con los repos nuevos: `carreras_repository.dart`). Cero errores/warnings, cero infos de otro tipo.

- [ ] **Step 2: Toda la batería de tests**

Run: `flutter test`
Expected: todo en verde (nuevos: documentos_postulacion, resolucion_carta, carrera; más los previos).

- [ ] **Step 3: Prueba manual en el teléfono (guía)**

Run: `flutter run --dart-define=API_BASE_URL=https://TU-URL.trycloudflare.com`

Verifica:
1. En el **Drawer**, Documentos / Carta de Respuesta / Perfil ya **no están atenuados** y navegan.
2. **Documentos**: con una postulación de tutor externo que tenga CV/título adjuntos, aparece la lista; tocar un documento abre el PDF en el visor externo. Sin documentos → "No hay documentos…".
3. **Carta de Respuesta**: si la postulación está aprobada/observada/rechazada, muestra la tarjeta de resolución (estado, fecha, motivo, próximo paso) con el botón de descarga **deshabilitado**; en otros estados → "todavía no tiene una resolución".
4. **Perfil**: muestra correo, teléfono y carrera (si tiene postulación). "Editar datos" guarda nombres/apellidos/teléfono y la cabecera se refresca. "Cambiar contraseña" pide actual + nueva; con la actual incorrecta muestra el error del backend.

---

## Self-review (cobertura del spec — sección "Tanda 2" del spec del 2026-06-13)

- Documentos con descarga real (URL firmada `GET /archivos/{id}`) → Tasks 1, 3, 4. ✅
- Carta de Respuesta (resolución; descarga deshabilitada como el web, R3) → Tasks 2, 5. ✅
- Perfil (`/auth/me` + carrera `/carreras/{id}` + editar `PATCH /auth/me` + cambiar contraseña `POST /auth/cambiar-password`) → Tasks 6, 7, 8. ✅
- Activar los 3 ítems del menú + rutas → Task 9. ✅
- Solo endpoints existentes; nada de backend nuevo → respetado (única acción deshabilitada: descarga de carta). ✅
- Tests de la lógica pura (documentos, resolución, carrera) → Tasks 3, 5, 6. ✅
- Notificaciones NO se incluye (queda para Tanda 3). ✅
