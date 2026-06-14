# AppUnivalle — Cómo funciona la aplicación

> App móvil (Flutter / Android) **solo para estudiantes** del sistema de
> titulaciones de la UniValle. Es un **cliente** del backend web existente
> (FastAPI): no tiene base de datos propia ni lógica de negocio propia; todo lo
> que muestra y guarda viaja al backend por HTTP. Hace **exactamente** lo que
> hace un estudiante en la página web, nada más.

Última actualización: 2026-06-14.

---

## 1. Resumen en una frase

La app pide datos al backend con peticiones HTTP, guarda un *token* de sesión en
el teléfono y dibuja pantallas con esa información. Si el backend no está
encendido y accesible, la app abre pero **no puede mostrar ni guardar nada**.

---

## 2. Stack y tecnologías

| Capa | Tecnología | Para qué |
|------|------------|----------|
| Framework | **Flutter** (Material 3, Dart SDK ^3.12) | UI multiplataforma (usamos Android) |
| Red / HTTP | **dio 5.7** | Hacer las peticiones al backend |
| Token seguro | **flutter_secure_storage 9.2** | Guardar el JWT y la URL del servidor |
| Estado | **provider 6.1** (`ChangeNotifier`) | Estado de sesión y de notificaciones |
| Navegación | **go_router 14.6** | Rutas + redirección según la sesión |
| Archivos | **file_picker 8.1** | Elegir el PDF a subir |
| Abrir PDF | **url_launcher 6.3** | Abrir documentos en el visor del teléfono |
| Notificaciones | **flutter_local_notifications 18.0** | Aviso del sistema con sonido (app abierta) |
| Tipografía | **google_fonts** (Inter) | Fuente del tema |

---

## 3. Conexión con el backend (lo más importante)

### 3.1 A qué se conecta
- El backend es la API **FastAPI** del sistema de titulaciones, que expone sus
  endpoints bajo el prefijo **`/api/v1`**.
- La app arma la URL final así: `<URL_del_servidor>` + `/api/v1`.
  Ejemplo: si el servidor es `https://algo.trycloudflare.com`, la app pega a
  `https://algo.trycloudflare.com/api/v1/...`.

### 3.2 Cómo se decide la URL del servidor
La URL base es **configurable**, en este orden de prioridad:

1. **Lo que el usuario guardó en la app** (pantalla *Configuración → Servidor*).
   Se guarda en el teléfono (`ServerConfigStore`) y se relee al arrancar.
2. Si no hay nada guardado: el valor de compilación
   `--dart-define=API_BASE_URL=...` (si se compiló con él).
3. Si tampoco: el *fallback* del código → `http://192.168.0.9:8000`
   (ver `lib/core/config/env.dart`).

> Nunca se usa `localhost`: en un teléfono físico apuntaría al propio teléfono,
> no a la PC del backend.

La URL se puede **cambiar en caliente** desde la app sin recompilar
(`ApiClient.updateServerBaseUrl`): útil para alternar entre IP de red local y un
túnel de Cloudflare.

### 3.3 Cómo viajan las peticiones
- Hay **un solo cliente Dio** central (`ApiClient`) que comparten todos los
  repositorios. Tiene *timeouts* (conexión 15s, recepción 20s, envío 30s) y
  cabeceras JSON por defecto.
- Un **interceptor de autenticación** (`AuthInterceptor`):
  - Añade `Authorization: Bearer <token>` a cada petición cuando hay sesión.
  - Si una petición **con token** recibe **401**, borra la sesión y manda al
    login (el token venció o fue rechazado). El backend usa JWT sin *refresh*:
    un 401 autenticado = "vuelve a iniciar sesión".
- Errores: cualquier `DioException` se traduce a un `ApiException` con mensaje
  legible; la UI nunca ve JSON crudo.

### 3.4 Autenticación (login)
- `POST /auth/login` con email + contraseña → devuelve un **access token (JWT)**.
- El token se guarda en `flutter_secure_storage`.
- Luego `GET /auth/me` trae el perfil. **Regla de negocio:** si el rol **no es
  `estudiante`**, se cierra la sesión y se muestra "Acceso denegado". Esta app es
  solo para estudiantes.
- *Auto-login*: al arrancar, si hay token guardado se valida con `/auth/me`; si
  sigue válido entra directo al Home.
- *Logout*: es **local** (se borra el token). El backend no tiene endpoint de
  logout porque el JWT es sin estado.

---

## 4. Endpoints del backend que usa la app

> Solo se usan endpoints **reales** del backend. La app no inventa ninguno.

| Función en la app | Método + ruta (bajo `/api/v1`) |
|-------------------|-------------------------------|
| Iniciar sesión | `POST /auth/login` |
| Perfil del usuario | `GET /auth/me` |
| Editar perfil | `PATCH /auth/me` |
| Cambiar contraseña | `POST /auth/cambiar-password` |
| Mis postulaciones | `GET /postulaciones/mis` |
| Detalle de una postulación | `GET /postulaciones/{id}` |
| Crear postulación | `POST /postulaciones` |
| Editar postulación | `PATCH /postulaciones/{id}` |
| Enviar a secretaría | `POST /postulaciones/{id}/enviar-a-secretaria` |
| Subir archivo (PDF) | `POST /archivos` |
| Obtener archivo (URL) | `GET /archivos/{id}` |
| Modalidades | `GET /modalidades?activa=true` |
| Tutores habilitados | `GET /tutores-habilitados` |
| Docentes | `GET /docentes` |
| Carrera por id | `GET /carreras/{id}` |
| Mis notificaciones | `GET /notificaciones/mis` |
| Contar no leídas | `GET /notificaciones/contar-no-leidas` |
| Marcar una leída | `PATCH /notificaciones/{id}/leer` |
| Marcar todas leídas | `POST /notificaciones/marcar-todas-leidas` |

---

## 5. Qué puede hacer el estudiante (funcionalidad)

Paridad con lo que hace el estudiante en la web:

- **Inicio:** saludo + resumen de la postulación más reciente (estado + pasos del
  proceso) y acceso a "Mis postulaciones".
- **Mis postulaciones:** lista de sus postulaciones con su estado.
- **Crear / editar / enviar postulación:** formulario con tema, modalidad,
  descripción, tutor (docente o externo). Permite **subir PDF** y **enviar a
  secretaría**. Solo es editable mientras la postulación está en estado editable.
- **Detalle de postulación.**
- **Observaciones:** lo que secretaría/comité observó.
- **Historial:** línea de tiempo de cambios de estado.
- **Documentos:** lista de documentos con opción de **descargar/abrir**.
- **Carta de respuesta:** resolución/carta cuando existe.
- **Perfil:** ver y editar datos, cambiar contraseña.
- **Notificaciones:** campana con contador (badge) + pantalla de notificaciones.
  Mientras la app está **abierta**, revisa cada 60s y, si hay nuevas, lanza un
  **aviso del sistema con sonido**. *(No es push real de FCM: eso requeriría
  cambios en el backend y queda fuera de alcance.)*

---

## 6. Estructura del proyecto (Feature-First)

```
lib/
├─ main.dart                 # arranque: construye dependencias y lanza la app
├─ app/
│  ├─ app.dart               # widget raíz, tema, providers, ciclo de vida
│  └─ router.dart            # rutas (go_router) + redirección por sesión
├─ core/                     # infraestructura compartida
│  ├─ config/                # env.dart (URL base) + server_config_store.dart
│  ├─ network/               # api_client (Dio), auth_interceptor, token_storage, api_exception
│  ├─ theme/app_theme.dart   # colores y tema Material 3 (carmesí UniValle)
│  ├─ utils/formato.dart     # formato de fechas, etc.
│  └─ widgets/               # piezas visuales reutilizables
│     ├─ brand_card.dart     # tarjeta blanca redondeada con sombra suave
│     ├─ hero_header.dart    # cabecera con degradado carmesí
│     ├─ section_header.dart # ícono + título de sección
│     ├─ form_section.dart   # sección de formulario con espaciado uniforme
│     └─ app_buttons.dart    # PrimaryButton / SecondaryButton
└─ features/                 # cada módulo: data / application / presentation
   ├─ auth/                  # login, sesión, perfil del usuario, splash
   ├─ estudiante/            # home del estudiante
   ├─ postulaciones/         # lista, detalle, formulario, observaciones, historial, documentos, carta
   ├─ archivos/              # subir/obtener PDFs
   ├─ catalogos/             # modalidades, tutores, docentes, carreras
   ├─ notificaciones/        # campana, pantalla, polling, aviso local con sonido
   ├─ perfil/                # pantalla de perfil
   ├─ configuracion/         # pantalla "Servidor" (cambiar URL del backend)
   └─ shell/                 # Drawer (menú lateral)
```

Dentro de cada *feature*:
- **data/** → modelos (`fromJson`) + repositorios (llamadas al backend).
- **application/** → lógica/estado (controllers `ChangeNotifier`, helpers).
- **presentation/** → pantallas y widgets.

Las dependencias de larga vida (storage, `ApiClient`, repositorios) se construyen
**una sola vez** en `AppDependencies.create()` (composition root) y se inyectan al
árbol de widgets.

---

## 7. Cómo arrancar / probar la app

- **En desarrollo (con tu PC conectada):** `flutter run`.
- **Generar el instalable para regalar:** `flutter build apk --release`
  → genera `build/app/outputs/flutter-apk/app-release.apk`.
- **Hornear la URL del backend al compilar (opcional):**
  `flutter build apk --release --dart-define=API_BASE_URL=https://tu-servidor`.
- Para que la app **funcione de verdad**, el dispositivo debe poder **alcanzar el
  backend** (misma red local, o un túnel/host público), y esa URL debe estar
  puesta en la app (pantalla *Servidor*) o horneada al compilar.

---

## 8. Tus dos preguntas

### A) "Si le paso la app a mi amiga que también tiene el backend y lo hace correr, ¿debería funcionar ahí también?"

**Sí, debería funcionar — con una condición clave:** la app tiene que **apuntar al
backend de tu amiga**.

La app es solo un cliente; no le importa *de quién* es el backend, solo necesita
una **URL alcanzable**. Entonces, en el teléfono de tu amiga:

1. Ella corre su backend.
2. En la app, va a **Configuración → Servidor** y pone la URL de **su** backend:
   - Si el teléfono está en la **misma red Wi-Fi** que su PC:
     `http://<IP-local-de-su-PC>:8000` (ej. `http://192.168.x.x:8000`).
   - Si usa un **túnel** (Cloudflare, ngrok, etc.) o un host público:
     la URL `https://...` que le dé ese túnel.
3. Inicia sesión con un usuario **estudiante** que exista en **la base de datos de
   su backend** (los usuarios viven en el backend, no en la app).

Cosas a tener en cuenta para que "simplemente funcione":
- La app y el backend deben **verse en la red** (misma Wi-Fi o URL pública). No
  basta con que el backend esté "corriendo" si el teléfono no lo alcanza.
- Si su backend corre en otro **puerto** o ruta, la URL debe reflejarlo.
- El backend debe permitir el origen (CORS no aplica a apps nativas, pero sí
  debe estar escuchando en una IP accesible, no solo en `127.0.0.1`).
- El usuario y la contraseña deben existir **en la base de datos de ella**; los
  datos que verá serán los de **su** backend, no los tuyos.

En resumen: **la misma app (APK) sirve para cualquier backend compatible**; solo
hay que cambiar la URL del servidor dentro de la app.

### B) "¿Al hacer la app cambiamos algo del backend?"

**No. No tocamos nada del backend.**

- La app es **100% cliente**: solo **consume** endpoints que **ya existían** en el
  backend (los de la tabla de la sección 4). No agrega, modifica ni elimina
  endpoints, tablas, ni configuración del servidor.
- Lo único que la app "cambia" es lo mismo que cambiaría un estudiante usando la
  **web**: crear/editar/enviar **sus** postulaciones, subir **sus** PDFs, editar
  **su** perfil, marcar **sus** notificaciones como leídas. Eso son **datos**
  normales que el backend ya sabía manejar, no cambios en el backend en sí.
- No se modificó código del backend, ni su esquema de base de datos, ni se
  inventaron rutas nuevas. Por eso la app puede apuntar a **cualquier** copia del
  backend (la tuya o la de tu amiga) sin adaptaciones.
