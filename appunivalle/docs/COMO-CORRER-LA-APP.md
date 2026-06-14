# Cómo correr AppUnivalle (guía para ejecutar el proyecto)

> Guía para descargar el proyecto desde GitHub y hacerlo correr apuntando a tu
> propio backend. La carpeta donde se trabaja es **la que contiene
> `pubspec.yaml`**, que en este repo es **`AppUnivalle/appunivalle`**. Todos los
> comandos de Flutter se ejecutan **dentro de esa carpeta**.

Repo: https://github.com/jhomymch03/AppUnivalle

---

## 0. Requisitos previos (instalar una sola vez)
- **Flutter SDK** + **Android Studio** (con el SDK de Android).
  Guía oficial: https://docs.flutter.dev/get-started/install
- Un **teléfono Android** con *Depuración USB* activada, **o** un **emulador** de
  Android Studio.
- Verifica que todo esté bien con:
  ```
  flutter doctor
  ```
  (Deben salir ✓ en Flutter y en Android toolchain.)

---

## 1. Descargar el proyecto
**Opción A — con git:**
```
git clone https://github.com/jhomymch03/AppUnivalle.git
```
**Opción B — sin git:** en la página del repo → botón **Code → Download ZIP** →
y **extraer** el ZIP.

---

## 2. Entrar a la carpeta correcta ⚠️ (la del proyecto Flutter)
El proyecto está **anidado un nivel**. La carpeta donde se trabaja es la que tiene
`pubspec.yaml`:
```
AppUnivalle/appunivalle
```
Abre una terminal y ubícate ahí:
```
cd AppUnivalle/appunivalle
```
> Para confirmar que estás en la carpeta correcta, lista los archivos y debes ver
> `pubspec.yaml`, y las carpetas `lib`, `android`, etc.

---

## 3. Instalar las dependencias
Dentro de `appunivalle`:
```
flutter pub get
```
(Esto recrea las librerías que no vienen en el repo. Es normal.)

---

## 4. Encender el backend
Corre **tu** backend en tu compu. Lo **clave** es que escuche en `0.0.0.0` (todas
las interfaces), **no** en `127.0.0.1`/`localhost`, para que el teléfono pueda
alcanzarlo. En FastAPI se levanta con uvicorn así:
```
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
> Adapta `app.main:app` al punto de entrada real de tu backend. Lo único
> imprescindible es el `--host 0.0.0.0`.

### Cómo logra el teléfono alcanzar tu backend (elige UNA opción)
No necesitas las dos; con una basta.

**Opción A — Misma red Wi-Fi (LAN), sin instalar nada extra**
- El teléfono y tu PC deben estar en la **misma red Wi-Fi**.
- Averigua la IP local de tu PC: en Windows abre una terminal y corre `ipconfig`,
  busca **"Dirección IPv4"** (algo como `192.168.0.15`).
- La URL será: `http://TU-IP-LOCAL:8000` (ej. `http://192.168.0.15:8000`).
- Si no conecta, puede ser el **Firewall de Windows**: permite el puerto 8000 o
  la app de Python cuando te lo pregunte.

**Opción B — Túnel (Cloudflare o ngrok), NO requiere el mismo Wi-Fi**
- Expone tu backend local a una URL pública `https://...`; funciona desde
  cualquier red (incluso datos móviles). Es la opción más flexible.
- Con tu backend ya corriendo en el puerto 8000, en otra terminal:
  - Cloudflare: `cloudflared tunnel --url http://localhost:8000`
  - o ngrok: `ngrok http 8000`
- Copia la URL `https://...` que te muestre. (Ojo: con el túnel rápido de
  Cloudflare la URL **cambia cada vez** que lo reinicias.)

> Nota: la URL que pondrás en la app (paso 6) es solo la **base**
> (`http://192.168.0.15:8000` o `https://...`). **No** agregues `/api/v1`: la app
> lo añade sola.

---

## 5. Correr la app
Con el teléfono conectado (o el emulador abierto), dentro de `appunivalle`:
```
flutter run
```
- Si quieres generar el instalable en vez de ejecutarla:
  ```
  flutter build apk --release
  ```
  El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 6. Conectar la app con tu backend
1. Abre la app → menú lateral (☰) → **Servidor**.
2. Pega la **URL de tu backend** (la del paso 4) y guarda.
3. Inicia sesión con un usuario con rol **estudiante** que exista en **tu** base
   de datos.
4. Listo: deberías ver tus postulaciones, observaciones, etc.

---

## Si algo falla
- **"No conecta / error de red":** revisa que el backend esté encendido y que la
  **URL en Servidor** sea correcta y alcanzable desde el teléfono (misma red o
  túnel).
- **"Acceso denegado":** el usuario no es estudiante. La app es **solo para
  estudiantes**.
- **Una pantalla concreta da error pero el resto va:** probablemente ese
  endpoint/campo cambió en el backend. Ver `docs/COMO-FUNCIONA-LA-APP.md`
  (sección 4 "Endpoints") para comparar el contrato que la app espera.
