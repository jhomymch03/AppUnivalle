# Revamp visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevar el aspecto visual de la app del estudiante con un tema centralizado + componentes reutilizables inspirados en el Stitch, sin cambiar datos, textos, lógica ni navegación.

**Architecture:** Un `AppTheme` centraliza color/tipografía/forma (Material 3, seed carmesí `#BA1A1A`, Inter vía `google_fonts`). Unos pocos widgets reutilizables (`HeroHeader`, `BrandCard`, `SectionHeader`, `PrimaryButton`/`SecondaryButton`) encapsulan el estilo y reciben el contenido por parámetros. Las pantallas envuelven su contenido EXISTENTE con esos widgets. Primer pase: Home + Formulario; luego el resto.

**Tech Stack:** Flutter (Material 3), google_fonts (nuevo). Sin cambios de datos/red.

> **Invariante:** no se modifica ningún texto mostrado, campo, validación, llamada a repositorio/endpoint ni la navegación (Drawer). No se añaden elementos sin datos reales. Los widgets existentes `EstadoBadge`, `StepperProceso`, `EstadoBanner` se dejan **como están** (ya tienen colores correctos alineados al web) salvo que el tema los mejore automáticamente.

> **Sin git:** no es repositorio git; cada tarea termina con checkpoint de `analyze`/`test` (no commit). `flutter analyze` sale != 0 ante cualquier `info`; los ~12 `prefer_initializing_formals` existentes son aceptables — solo importan errores/warnings o infos nuevos.

> **Verificación de lógica:** este trabajo es visual; `flutter test` debe seguir en verde **sin cambios** en los tests. No se agregan tests nuevos.

---

## Estructura de archivos

**Crear:**
- `lib/core/theme/app_theme.dart` — `AppColors` + `AppTheme.light()`.
- `lib/core/widgets/brand_card.dart` — `BrandCard`.
- `lib/core/widgets/section_header.dart` — `SectionHeader`.
- `lib/core/widgets/hero_header.dart` — `HeroHeader`.
- `lib/core/widgets/app_buttons.dart` — `PrimaryButton`, `SecondaryButton`.

**Modificar:**
- `pubspec.yaml` — agrega `google_fonts`.
- `lib/app/app.dart` — usa `AppTheme.light()` en vez del `ThemeData` inline.
- `lib/features/estudiante/presentation/home_estudiante_screen.dart` — aplica HeroHeader/BrandCard/botones.
- `lib/features/postulaciones/presentation/postulacion_form_screen.dart` — aplica SectionHeader/botones.
- (Pase 2) resto de pantallas del estudiante.

---

## Task 1: Dependencia google_fonts

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Agregar el paquete**

En `pubspec.yaml`, dentro de `dependencies:`, debajo de `flutter_local_notifications: ^18.0.1`, agrega:

```yaml
  google_fonts: ^6.2.1           # tipografia Inter para el tema
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: "Got dependencies!". Si la versión exacta conflictúa, usa la última `6.x` que `pub` acepte.

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze`
Expected: sin errores nuevos.

---

## Task 2: AppColors + AppTheme + wiring en app.dart

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/app/app.dart`

- [ ] **Step 1: Crear el tema**

```dart
// lib/core/theme/app_theme.dart
/// Tema centralizado de la app (paleta carmesi + Inter + radios/sombras),
/// inspirado en el diseno Stitch. Un solo lugar para el estilo global.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color (extraidos del Stitch).
abstract final class AppColors {
  static const primary = Color(0xFFBA1A1A);
  static const primaryDark = Color(0xFF8E1230); // para el degradado del hero
  static const fondo = Color(0xFFFBF9F9);
  static const tarjeta = Color(0xFFFFFFFF);
  static const superficieSutil = Color(0xFFF5F3F3);
  static const borde = Color(0xFFE3E2E2);
  static const texto = Color(0xFF1B1C1C);
  static const rosaContenedor = Color(0xFFFFDAD6);
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      surface: AppColors.tarjeta,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.texto, displayColor: AppColors.texto),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.tarjeta,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficieSutil,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borde),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Usarlo en app.dart**

En `lib/app/app.dart`, agrega el import:

```dart
import '../core/theme/app_theme.dart';
```

Y en el `MaterialApp.router`, reemplaza el bloque `theme: ThemeData(...)` por:

```dart
        theme: AppTheme.light(),
```

(Elimina el `ThemeData(colorScheme: ColorScheme.fromSeed(...), useMaterial3: true)` inline.)

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze lib/core/theme/app_theme.dart lib/app/app.dart`
Expected: sin errores. (Si `cardTheme` reclama el tipo, en esta versión de Flutter es `CardThemeData` — ya usado arriba.)

Run: `flutter test`
Expected: en verde (sin cambios).

---

## Task 3: BrandCard

**Files:**
- Create: `lib/core/widgets/brand_card.dart`

- [ ] **Step 1: Crear el widget**

```dart
// lib/core/widgets/brand_card.dart
/// Tarjeta blanca redondeada con sombra suave y padding consistente.
/// Envuelve contenido existente; no contiene logica.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contenido =
        Padding(padding: padding ?? const EdgeInsets.all(16), child: child);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? contenido
          : InkWell(onTap: onTap, child: contenido),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/core/widgets/brand_card.dart`
Expected: sin errores.

---

## Task 4: SectionHeader

**Files:**
- Create: `lib/core/widgets/section_header.dart`

- [ ] **Step 1: Crear el widget**

```dart
// lib/core/widgets/section_header.dart
/// Encabezado de seccion: icono en cuadrito rosa + titulo (+ trailing opcional).
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.titulo,
    this.trailing,
  });

  final IconData icon;
  final String titulo;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.rosaContenedor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/core/widgets/section_header.dart`
Expected: sin errores.

---

## Task 5: HeroHeader

**Files:**
- Create: `lib/core/widgets/hero_header.dart`

- [ ] **Step 1: Crear el widget**

```dart
// lib/core/widgets/hero_header.dart
/// Cabecera "hero" con degradado carmesi, titulo/subtitulo en blanco y una
/// pildora opcional. Recibe su contenido; no inventa datos.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.pildora,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? pildora;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitulo!,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          if (pildora != null) ...[const SizedBox(height: 12), pildora!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/core/widgets/hero_header.dart`
Expected: sin errores.

---

## Task 6: PrimaryButton / SecondaryButton

**Files:**
- Create: `lib/core/widgets/app_buttons.dart`

- [ ] **Step 1: Crear los botones**

```dart
// lib/core/widgets/app_buttons.dart
/// Botones uniformes (envoltorios delgados sobre Filled/Outlined). El estilo
/// (forma, altura) viene del tema; aqui solo se unifica texto + icono opcional.
library;

import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/core/widgets/app_buttons.dart`
Expected: sin errores.

---

## Task 7: Aplicar el estilo al Home

**Files:**
- Modify: `lib/features/estudiante/presentation/home_estudiante_screen.dart`

- [ ] **Step 1: Imports de los componentes**

Agrega:

```dart
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/hero_header.dart';
import '../../../core/widgets/app_buttons.dart';
```

- [ ] **Step 2: Reemplazar el saludo por HeroHeader**

En el `ListView` del `build`, reemplaza los tres widgets del saludo:

```dart
            Text(
              'Hola, ${usuario?.nombres ?? ''} 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(usuario?.email ?? ''),
            const SizedBox(height: 20),
```

por:

```dart
            HeroHeader(
              titulo: 'Hola, ${usuario?.nombres ?? ''} 👋',
              subtitulo: usuario?.email,
            ),
            const SizedBox(height: 20),
```

- [ ] **Step 3: `_ResumenActual` con BrandCard + botones**

En `_ResumenActual.build`, reemplaza el `Card(child: Padding(...))` que envuelve la fila código/título/badge por un `BrandCard(child: ...)` con el mismo contenido interno (quita el `Card`+`Padding` externos; `BrandCard` ya trae padding). Es decir:

```dart
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.codigoCorto,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          p.titulo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  EstadoBadge(estado: p.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Actualizada el ${formatFecha(p.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
```

Y reemplaza los botones (`FilledButton.icon` / `OutlinedButton.icon`) por:

```dart
        if (esEditable(p.estado)) ...[
          PrimaryButton(
            label: 'Editar / Enviar',
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/postulacion/nueva'),
          ),
          const SizedBox(height: 8),
        ],
        SecondaryButton(
          label: total > 1
              ? 'Ver mis postulaciones ($total)'
              : 'Ver mis postulaciones',
          icon: Icons.folder_shared_outlined,
          onPressed: () => context.push('/mis-postulaciones'),
        ),
```

- [ ] **Step 4: `_SinPostulaciones` y `_ErrorCard` con BrandCard + PrimaryButton**

En `_SinPostulaciones.build`, cambia el `Card(child: Padding(padding: EdgeInsets.all(24), child: ...))` por `BrandCard(padding: const EdgeInsets.all(24), child: ...)` con el mismo `Column` interno, y reemplaza el `FilledButton.icon` final por:

```dart
            PrimaryButton(
              label: 'Crear postulación',
              icon: Icons.add,
              onPressed: () => context.push('/postulacion/nueva'),
            ),
```

En `_ErrorCard.build`, cambia el `Card(child: Padding(...))` por `BrandCard(padding: const EdgeInsets.all(20), child: ...)` con el mismo contenido y deja el botón Reintentar como `FilledButton` (o `PrimaryButton(label: 'Reintentar', onPressed: onReintentar)`).

- [ ] **Step 5: Checkpoint**

Run: `flutter analyze lib/features/estudiante/presentation/home_estudiante_screen.dart`
Expected: sin errores. Verifica que no quedaron imports sin usar (si `Card` ya no se usa, no pasa nada: es del framework).

---

## Task 8: Aplicar el estilo al Formulario

**Files:**
- Modify: `lib/features/postulaciones/presentation/postulacion_form_screen.dart`

- [ ] **Step 1: Imports**

Agrega:

```dart
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/app_buttons.dart';
```

- [ ] **Step 2: Encabezados de sección**

En `_buildForm`, reemplaza el título de sección "Datos del proyecto":

```dart
        Text('Datos del proyecto',
            style: Theme.of(context).textTheme.titleMedium),
```

por:

```dart
        const SectionHeader(
            icon: Icons.description_outlined, titulo: 'Datos del proyecto'),
```

Y reemplaza el título "Tutor propuesto":

```dart
        Text('Tutor propuesto', style: Theme.of(context).textTheme.titleMedium),
```

por:

```dart
        const SectionHeader(
            icon: Icons.person_outline, titulo: 'Tutor propuesto'),
```

- [ ] **Step 3: Botones primario/secundario**

En la fila de acciones (`Row` con los dos botones), reemplaza el `OutlinedButton` de Guardar y el `FilledButton` de Enviar por `SecondaryButton`/`PrimaryButton`, conservando exactamente los mismos `onPressed`, labels y condiciones de `disabled`. Ejemplo del de Guardar:

```dart
            Expanded(
              child: SecondaryButton(
                label: _guardando
                    ? 'Guardando...'
                    : (a == null ? 'Crear borrador' : 'Guardar cambios'),
                onPressed: (!_editable || _guardando) ? null : _guardar,
              ),
            ),
```

Y el de Enviar:

```dart
              Expanded(
                child: PrimaryButton(
                  label: _enviando ? 'Enviando...' : 'Enviar a secretaría',
                  onPressed: (!puedeEnviar || _enviando) ? null : _enviar,
                ),
              ),
```

(No cambies la lógica de `puedeEnviar`, `_editable`, `_guardando`, `_enviando`.)

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/postulacion_form_screen.dart`
Expected: sin errores.

Run: `flutter test`
Expected: en verde.

> **CHECKPOINT DE USUARIO:** este es el momento de probar Home + Formulario en el teléfono y validar el look antes de extender al resto (Task 9).

---

## Task 9: Extender el estilo al resto de pantallas

**Files (modificar, mismo patrón en cada una):**
- `mis_postulaciones_screen.dart`, `postulacion_detalle_screen.dart`,
  `observaciones_screen.dart`, `historial_screen.dart`, `documentos_screen.dart`,
  `carta_respuesta_screen.dart` (todas en `lib/features/postulaciones/presentation/`),
  `lib/features/perfil/presentation/perfil_screen.dart`,
  `lib/features/notificaciones/presentation/notificaciones_screen.dart`.

- [ ] **Step 1: Aplicar el patrón en cada pantalla**

Para cada archivo, aplica estos cambios manteniendo intactos datos/lógica/navegación:

1. Importa lo que uses: `../../../core/widgets/brand_card.dart`,
   `../../../core/widgets/section_header.dart`,
   `../../../core/widgets/app_buttons.dart` (ajusta `../` según ubicación; todas
   están en `lib/features/<x>/presentation/`, así que `../../../core/widgets/...`).
2. **Tarjetas:** reemplaza los `Card(child: Padding(padding: EdgeInsets.all(16), child: X))`
   por `BrandCard(child: X)` (quitando el `Padding` externo redundante). En las
   tarjetas de lista que usan `InkWell` con `onTap`, usa `BrandCard(onTap: ..., child: X)`.
3. **Encabezados de sección** (p. ej. "Información general" en el detalle,
   "Mi cuenta" secciones del perfil): donde haya un título de sección con
   `Theme...titleMedium/titleSmall`, envuélvelo con `SectionHeader(icon: <icono acorde>, titulo: '<mismo texto>')`.
   Iconos sugeridos: Detalle/Información → `Icons.info_outline`; Documentos →
   `Icons.folder_outlined`; Observaciones → `Icons.comment_outlined`; Historial →
   `Icons.history`; Carta → `Icons.mail_outline`; Perfil → `Icons.person_outline`.
4. **Botones:** reemplaza `FilledButton`/`FilledButton.icon` por `PrimaryButton` y
   `OutlinedButton`/`OutlinedButton.icon` por `SecondaryButton`, conservando label,
   icono, `onPressed` y condiciones de `disabled` EXACTOS.
5. **No** cambies textos, campos, condiciones, ni el orden de la información.

> No toques `EstadoBadge`, `StepperProceso`, `EstadoBanner`, `ObservacionesPanel`,
> `TimelineHistorial` (ya alineados; heredan colores del tema). No toques las
> pantallas de auth/splash/acceso-denegado/config de servidor ni el `AppDrawer`
> en esta tarea (su estilo viene del tema).

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze`
Expected: solo los `info - prefer_initializing_formals` conocidos. Cero errores/warnings.

---

## Task 10: Verificación final

**Files:** —

- [ ] **Step 1: Análisis estático completo**

Run: `flutter analyze`
Expected: solo `info - prefer_initializing_formals`. Cero errores/warnings/otros infos.

- [ ] **Step 2: Toda la batería de tests**

Run: `flutter test`
Expected: todo en verde, **mismo número de tests que antes** (no se agregaron ni cambiaron tests).

- [ ] **Step 3: Prueba visual en el teléfono (guía)**

Run: `flutter run --dart-define=API_BASE_URL=https://TU-URL.trycloudflare.com`

Verifica que TODAS las pantallas se ven con el nuevo estilo (cabecera hero en Home,
tarjetas redondeadas con sombra, encabezados de sección con ícono rosa, botones
carmesí/borde, tipografía Inter) y que **la información y la navegación son
idénticas** a antes (mismos datos, mismos campos, mismo Drawer, mismas acciones).

---

## Self-review (cobertura del spec)

- Tema centralizado (paleta carmesí, superficies cálidas, Inter, radios/sombras) + uso en `app.dart` → Tasks 1, 2. ✅
- 4 componentes reutilizables (`HeroHeader`, `BrandCard`, `SectionHeader`, `PrimaryButton`/`SecondaryButton`) → Tasks 3–6. ✅
- Primer pase Home + Formulario → Tasks 7, 8 (con checkpoint de usuario). ✅
- Extensión al resto → Task 9. ✅
- Invariantes (sin tocar datos/lógica/navegación; sin elementos inventados; widgets de estado intactos) → notas en cada tarea + Task 9 Step 1.5. ✅
- Verificación (analyze + test en verde sin cambios de tests) → Task 10. ✅
- `google_fonts` para Inter → Task 1. ✅
