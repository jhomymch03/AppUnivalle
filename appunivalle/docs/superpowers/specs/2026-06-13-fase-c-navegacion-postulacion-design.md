# Fase C — Navegación del estudiante + Crear/Editar/Enviar postulación

- **Fecha:** 2026-06-13
- **App:** AppUnivalle (Flutter) — rol estudiante
- **Backend:** Sistema de Titulaciones UniValle (FastAPI, `/api/v1`)
- **Principio rector:** la app del estudiante debe hacer **exactamente lo que hace
  la interfaz web del estudiante** — ni más ni menos — antes de agregar extras.

## Contexto

Fase A (auth + sesión + guard de rol estudiante) y Fase B ("Mis Postulaciones" y
detalle, solo lectura) ya están completas. Esta fase agrega:

1. La **navegación lateral** (Navigation Drawer) que replica el sidebar del
   estudiante del web.
2. El **flujo de escritura** de la postulación: crear, editar, subir PDFs y
   enviar a secretaría (Fase C propiamente dicha).

El menú del estudiante en el web (`frontend/src/utils/navigation.ts`) tiene 8
ítems, en este orden:

| # | Ítem | Página web | Qué muestra |
|---|---|---|---|
| 1 | Dashboard | `Dashboard.vue` (`WidgetEstudiante`) | Resumen de la postulación activa (estado + stepper) |
| 2 | Nueva Postulación | `estudiante/Postulacion.vue` | Formulario: crea si no hay activa, edita si la hay |
| 3 | Mis Postulaciones | `estudiante/MisPostulaciones.vue` | Lista de todas las postulaciones |
| 4 | Observaciones | `estudiante/Observaciones.vue` | Observaciones de la activa, agrupadas por ronda |
| 5 | Documentos | `estudiante/Documentos.vue` | Archivos del expediente **con descarga** (URL firmada) |
| 6 | Historial | `estudiante/Historial.vue` | Timeline de **todas** las postulaciones |
| 7 | Carta de Respuesta | `estudiante/CartaRespuesta.vue` | Resolución + próximo paso (descarga de PDF deshabilitada) |
| 8 | Perfil | `estudiante/Perfil.vue` | Mi cuenta + editar datos + cambiar contraseña |

En el web, **Dashboard y Nueva Postulación son la misma postulación activa**;
Observaciones, Documentos, Historial y Carta de Respuesta son **facetas** de esa
postulación. En Fase B estas facetas se habían consolidado en la pantalla de
Detalle; esta fase las separa en ítems de menú para igualar al web.

## Decisiones de diseño (cerradas con el usuario)

1. **Una postulación activa a la vez** (convención del web; el backend no la
   impone). `activa` = la más reciente con `estado_actual != "RECHAZADO"` y sin
   `deleted_at`. Si no hay ninguna (o todas están rechazadas) → `null` → el
   formulario se muestra vacío para crear.
2. **Botón "Crear" contextual**, no global: el ítem "Nueva Postulación" del drawer
   abre el formulario que decide solo crear vs editar; el Home muestra atajos
   "Crear" (si no hay activa) o "Editar"/"Enviar" (si la activa es editable).
3. **Modalidades desde el endpoint** `GET /api/v1/modalidades?activa=true`
   (enviando el `nombre`), con **fallback** a la constante del web
   (`["Proyecto de grado", "Tesis", "Trabajo dirigido"]`) si la llamada falla o
   devuelve vacío. El backend guarda `modalidad` como texto libre (3–100 chars).
4. **Navegación por Navigation Drawer** (no bottom-nav): es el equivalente móvil
   directo del sidebar web y escala bien a 8 destinos.
5. **Responder observaciones queda FUERA**: el web del estudiante no expone ese
   endpoint (`POST /{id}/observaciones/{obs}/responder` solo aparece en el OpenAPI
   generado, no en ninguna pantalla). La forma de "responder" del web es **editar
   y reenviar** con cambios.
6. **Carta de postulación queda FUERA**: está deshabilitada en el web (pendiente
   backend R1/R2).
7. **Secuencia por partes**: Tanda 1 = Drawer + Fase C + enganchar pantallas
   existentes; Tanda 2 = Documentos con descarga + Carta de Respuesta + Perfil.

## Endpoints del backend usados (solo los que existen)

- `POST   /api/v1/postulaciones` → crear en BORRADOR (solo estudiante). Body
  `PostulacionInput`. La `carrera_id` y `estudiante_id` los infiere el backend.
- `PATCH  /api/v1/postulaciones/{id}` → editar. Semántica PATCH: solo se tocan los
  campos enviados (`model_fields_set`). Solo en estados editables.
- `POST   /api/v1/postulaciones/{id}/enviar-a-secretaria` → envío inicial o reenvío.
- `GET    /api/v1/postulaciones/mis` → lista (ya usado en Fase B).
- `GET    /api/v1/postulaciones/{id}` → detalle + historial + observaciones (Fase B).
- `POST   /api/v1/archivos` → subir PDF (multipart `file`, solo `application/pdf`,
  máx 10 MB) → devuelve `{ id, url, nombre_original, ... }`.
- `GET    /api/v1/tutores-habilitados` → registros `{ docente_id, carrera_id, activo }`.
- `GET    /api/v1/docentes` → catálogo `{ id, nombres, apellidos, especialidad }`.
- `GET    /api/v1/modalidades?activa=true` → `{ codigo, nombre, activa }`.

**Tanda 2 adicionalmente:** `GET /api/v1/archivos/{id}` (metadata + URL firmada),
`GET /api/v1/carreras/{id}`, `PATCH /api/v1/auth/me`, `POST /api/v1/auth/cambiar-password`.

## Reglas del formulario (espejo del web)

- `titulo`: requerido, 5–500 caracteres.
- `descripcion`: requerida, ≥ 10 caracteres.
- `modalidad`: requerida (de la lista).
- `tipo_tutor`: `interno` | `externo` (radio).
- Si `interno` → `tutor_docente_id` requerido (de la lista de habilitados).
- Si `externo` → `tutor_externo_nombres` y `tutor_externo_apellidos` requeridos
  (≥ 2 chars); `ci`, `email` (formato si se llena), `telefono`, CV y título PDF
  son opcionales.
- Al armar el payload: si `interno`, los campos `tutor_externo_*` van en `null`;
  si `externo`, `tutor_docente_id` va en `null` (limpieza cruzada como el web).

**Estados y permisos de UI** (de `Postulacion.vue`):

| Estado | Formulario | Enviar |
|---|---|---|
| BORRADOR | editable | ✅ |
| OBSERVADO_SECRETARIA / OBSERVADO_DIRECCION | editable | ✅ ("Reenviar con cambios") |
| ENVIADO_A_SECRETARIA / EN_REVISION_DIRECCION_CAT / APROBADO / PAUSADO_POR_ABANDONO | solo lectura | ❌ |

El botón "Enviar" requiere además marcar la **declaración de veracidad** (checkbox).

## Arquitectura (Feature-First, consistente con Fases A/B)

### Navegación

- Nueva `ShellRoute` en `lib/app/router.dart` que envuelve las pantallas del
  estudiante con un `Scaffold` que tiene el `Drawer`.
- Nuevo widget `lib/features/shell/presentation/app_drawer.dart`:
  - Cabecera con nombre + correo del usuario (de `SessionController`).
  - Lista declarativa de ítems `{ label, icon, ruta, habilitado }` (los 3 de
    Tanda 2 se renderizan atenuados con etiqueta "Próximamente").
  - Resalta el ítem de la ruta actual.
  - Pie: "Servidor" (config) y "Cerrar sesión".
- Rutas nuevas: `/postulacion/nueva` (form), `/observaciones`, `/historial`.
  (Tanda 2: `/documentos`, `/carta-respuesta`, `/perfil`.)
- El redirect por sesión existente sigue vigente (las nuevas rutas son
  protegidas).

### Capa de datos

`lib/features/postulaciones/data/postulaciones_repository.dart` (extender):
- `Future<Postulacion> crear(PostulacionPayload payload)` → `POST /postulaciones`.
- `Future<Postulacion> editar(String id, Map<String,dynamic> camposTocados)` →
  `PATCH /postulaciones/{id}` (solo campos presentes).
- `Future<Postulacion> enviarASecretaria(String id)` → `POST /{id}/enviar-a-secretaria`.

`lib/features/archivos/data/archivos_repository.dart` (nuevo):
- `Future<ArchivoSubido> subir({ required List<int> bytes, required String nombre })`
  → multipart `POST /archivos` (campo `file`, content-type `application/pdf`).
- Maneja 422 (tipo/tamaño) → `ApiException` con el `detail` del backend.

`lib/features/catalogos/data/` (nuevo):
- `tutores_repository.dart` → `Future<List<TutorOption>> listarOpcionesTutor()`:
  trae habilitados + docentes, los cruza por `docente_id`, filtra `activo`, arma
  `TutorOption { docenteId, nombreCompleto, especialidad }`, ordena por nombre.
- `modalidades_repository.dart` → `Future<List<String>> listar()`:
  `GET /modalidades?activa=true` → nombres; si falla o vacío, devuelve la constante
  de fallback.

### Modelos nuevos

- `PostulacionPayload` (en `data/models/`) con `toCreateJson()` y
  `toPatchJson(Set<String> camposTocados)` (limpieza cruzada interno/externo).
- `TutorOption { String docenteId; String nombreCompleto; String? especialidad; }`.
- `ArchivoSubido { String id; String url; String nombre; }`.

### Presentación

- `lib/features/postulaciones/presentation/postulacion_form_screen.dart`:
  - Secciones: "Datos del proyecto" (título, modalidad dropdown, descripción),
    "Tutor propuesto" (radio interno/externo → bloque condicional), declaración
    de veracidad, acciones (Guardar / Enviar).
  - Carga `activa` (vía `listarMias()` + `pickActiva`), modalidades y opciones de
    tutor al iniciar.
  - Readonly según estado; mensajes de error del backend.
  - Tras crear/editar/enviar: refresca y muestra feedback (SnackBar).
- `lib/features/postulaciones/presentation/observaciones_screen.dart`: carga la
  activa + su detalle, muestra `ObservacionesPanel` (widget existente) o estado
  vacío con enlace a "Nueva Postulación".
- `lib/features/postulaciones/presentation/historial_screen.dart`: lista todas las
  postulaciones; por cada una, cabecera (código, título, modalidad·tutor·fecha,
  badge, marca "Vigente" en la activa) + `TimelineHistorial` (widget existente).
- Widget `lib/features/archivos/presentation/archivo_upload_field.dart`: botón
  para elegir PDF (`file_picker`), sube, muestra nombre + estado (subiendo / ok /
  error), expone el `id` al formulario; permite quitar.
- Widget selector de tutor interno (dropdown con búsqueda sobre `TutorOption`).
- Home (`home_estudiante_screen.dart`): atajos contextuales "Crear" /
  "Editar" / "Enviar" según el estado de la activa.

### Dependencia nueva

- `file_picker` en `pubspec.yaml` (selección de archivos en Android). El permiso
  de lectura ya está cubierto; verificar configuración mínima de plataforma.

## Manejo de errores

- Todas las llamadas pasan por el `ApiClient`/Dio existente y convierten
  `DioException` → `ApiException` mostrando el `detail` del backend.
- Casos relevantes: 409 (estado no editable / no enviable), 422 (datos de tutor
  inconsistentes o archivo inválido). Se muestran como mensaje inline o SnackBar.

## Tests

- Unitarios del builder de payload:
  - crear con tutor interno limpia los `tutor_externo_*` (van `null`).
  - crear con tutor externo limpia `tutor_docente_id` (va `null`).
  - `toPatchJson` incluye solo los campos marcados como tocados.
- Validación condicional del formulario (interno requiere docente; externo
  requiere nombres + apellidos; email con formato).
- Parser de `TutorOption` (cruce habilitados ⨝ docentes; descarta sin match;
  filtra inactivos).

## Fuera de alcance de la Tanda 1 (documentado para Tanda 2)

- **Documentos** con descarga real (abrir/guardar PDF vía URL firmada de
  `GET /archivos/{id}`).
- **Carta de Respuesta**: pantalla de resolución (aprobado/observado/rechazado),
  motivo, fechas y próximo paso; botón de descarga **deshabilitado** (igual que el
  web, pendiente backend R3).
- **Perfil**: "Mi cuenta" con datos de `/auth/me`, carrera derivada de la
  postulación activa (`GET /carreras/{id}`), edición de datos (`PATCH /auth/me`) y
  cambio de contraseña (`POST /auth/cambiar-password`).
- Notificaciones (campana) — futura fase, fuera del menú del estudiante salvo
  como ítem transversal.

## Criterios de aceptación (Tanda 1)

1. El estudiante ve un Drawer con los 8 ítems; los 5 activos navegan y el actual
   se resalta; los 3 de Tanda 2 aparecen atenuados como "Próximamente".
2. Sin postulación activa, "Nueva Postulación" muestra el formulario vacío;
   crear deja la postulación en BORRADOR y vuelve a aparecer prellenada.
3. Con una activa editable, el formulario permite editar (PATCH parcial) y enviar
   a secretaría tras marcar la declaración de veracidad.
4. Con tutor externo, se pueden adjuntar CV y título en PDF (≤ 10 MB) y quedan
   referenciados en la postulación.
5. Con una activa en estado de solo lectura, el formulario se muestra readonly y
   sin botón de enviar.
6. Observaciones e Historial muestran la información de la activa / de todas las
   postulaciones, respectivamente, replicando el web.
7. `flutter analyze` sin errores y `flutter test` en verde.
