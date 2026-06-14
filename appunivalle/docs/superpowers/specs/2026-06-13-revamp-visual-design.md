# Revamp visual — Sistema de diseño + aplicación (estudiante)

- **Fecha:** 2026-06-13
- **App:** AppUnivalle (Flutter) — rol estudiante
- **Referencia visual:** export de Stitch en `Downloads/stitch_sistema_de_aprobaci_n_de_temas/`
  (pantallas `panel_de_control_estudiante`, `postulaci_n_de_tesis`, `aprobaci_n_y_seguimiento`).
- **Principio rector:** el Stitch es **inspiración de estilo**, no una especificación
  literal. Se toma su lenguaje visual y se aplica a la información y funciones que
  YA tiene la app. **No se cambia ningún dato, texto, campo, endpoint ni la
  navegación** — solo el aspecto visual. No se añaden elementos del Stitch que no
  correspondan a datos reales (p. ej. "25% progreso", estrellas de rating,
  "Biblioteca Digital", "Asistencia Técnica", "ID Matrícula", "Período Académico",
  marca "Scholarly Monolith").

## Contexto

La app del estudiante está funcionalmente completa (Fases A–D). Este trabajo es
puramente de **presentación**: unificar y elevar el estilo visual con un sistema
de diseño ligero inspirado en el Stitch, preservando intacto lo que se muestra y
cómo funciona.

## Tokens de diseño (extraídos del Stitch)

- **Primario (carmesí):** `#BA1A1A`.
- **Fondo cálido:** `#FBF9F9`. **Tarjetas:** `#FFFFFF`. Superficies sutiles:
  `#F5F3F3`/`#F2F0F0`. **Bordes:** `#E3E2E2`/`#DBDAD9`.
- **Texto (on-surface):** `#1B1C1C`; variante tenue para subtítulos.
- **Acentos rosa (contenedores de ícono / chips suaves):** `#FFDAD6`, `#FFD9DF`,
  `#FFB2BC`.
- **Tipografía:** **Inter** (pesos 400/500/600/700/800).
- **Radios:** tarjetas 16, inputs/botones 12, chips/píldoras/avatars full.
- **Sombra:** suave (equivalente a `shadow-sm`: baja opacidad, poco blur).

Estos tokens encajan con un `ColorScheme` Material 3 generado por `seed` =
`#BA1A1A`, ajustando superficies a los tonos cálidos de arriba.

## Decisiones de diseño (cerradas con el usuario)

1. **Enfoque:** sistema de diseño ligero — un **tema centralizado** + un puñado de
   **widgets reutilizables**, aplicados a las pantallas (no retoque disperso por
   pantalla).
2. **Alcance / orden:** primer pase = **Home + Formulario** (para validar el look);
   luego extender al resto de pantallas del estudiante.
3. **Navegación intacta:** se mantiene el Navigation Drawer (no se adopta el bottom
   nav del Stitch, que además incluía destinos de roles que no usamos).
4. **Tipografía Inter** vía el paquete `google_fonts` (cachea tras la 1.ª carga).
   Alternativa documentada: empaquetar el `.ttf` como asset si se quiere 100%
   offline; se decide en implementación si `google_fonts` da problemas.
5. **Aportes propios permitidos** (más allá del Stitch): espaciado consistente,
   estados vacíos/de error más cuidados, contraste accesible, iconografía coherente.

## Arquitectura

### Tema — `lib/core/theme/app_theme.dart`

- `AppColors` — constantes con los tokens de color de arriba.
- `AppTheme.light()` → `ThemeData` Material 3:
  - `colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, ...)` con
    `surface`/`background` ajustados a los tonos cálidos.
  - `textTheme`: Inter (via `google_fonts`).
  - Temas de componentes: `cardTheme` (radio 16, sombra suave, color blanco),
    `inputDecorationTheme` (radio 12, borde tenue, relleno), `filledButtonTheme` /
    `outlinedButtonTheme` (radio 12, alturas cómodas), `chipTheme`,
    `appBarTheme` (fondo del color de superficie, sin sombra dura).
- `app.dart` deja de declarar el `ThemeData` inline y usa `AppTheme.light()`.

### Componentes reutilizables — `lib/core/widgets/`

- `hero_header.dart` — `HeroHeader({required String titulo, String? subtitulo, Widget? pildora, Widget? trailing})`:
  contenedor con degradado carmesí, esquinas redondeadas, texto en blanco; `pildora`
  opcional (chip translúcido) y `trailing` opcional. Sin datos propios: recibe lo
  que la pantalla ya tiene.
- `brand_card.dart` — `BrandCard({required Widget child, EdgeInsets? padding, VoidCallback? onTap})`:
  tarjeta blanca redondeada (16) con sombra suave y padding por defecto (16);
  envuelve contenido existente.
- `section_header.dart` — `SectionHeader({required IconData icon, required String titulo, Widget? trailing})`:
  fila con ícono en cuadrito rosa redondeado + título; `trailing` opcional (p. ej.
  un chip de estado).
- `app_buttons.dart` — `PrimaryButton` (FilledButton estilizado, ícono opcional) y
  `SecondaryButton` (OutlinedButton estilizado). Envoltorios delgados sobre los
  botones de Material para uniformar texto/ícono/altura.

Cada widget tiene una única responsabilidad y recibe su contenido por parámetros
(no contiene lógica de negocio ni llamadas de red).

### Restyle de widgets existentes (sin cambiar su API ni sus datos)

- `EstadoBadge` — chip con el color del tono del estado (ya mapea tono→color);
  ajustar a píldora redondeada con el estilo del tema.
- `StepperProceso` — alinear colores/espaciado al tema.
- `EstadoBanner` — usar `BrandCard`/colores del tema.

### Aplicación — primer pase

- **Home (`home_estudiante_screen.dart`):** `HeroHeader` con el saludo y datos que
  ya se muestran ("Hola, {nombres}"); el resumen de la postulación reciente
  (código, título, `EstadoBadge`, `StepperProceso`) dentro de `BrandCard`; botones
  con `PrimaryButton`/`SecondaryButton`. Estado vacío y de error con el nuevo estilo.
  Mismos datos y navegación.
- **Formulario (`postulacion_form_screen.dart`):** secciones con `SectionHeader`
  ("Datos del proyecto", "Tutor propuesto"); inputs heredan el
  `inputDecorationTheme`; `ArchivoUploadField` con aspecto de "zona de carga"
  (contenedor punteado + ícono), sin cambiar su comportamiento; botones
  primario/secundario. Mismos campos, validación y flujo.

### Aplicación — pases siguientes (mismos componentes)

Detalle, Observaciones, Historial, Documentos, Carta de Respuesta, Perfil, Mis
Postulaciones y Notificaciones: envolver su contenido en `BrandCard`/`SectionHeader`
y usar los botones/colores del tema. Sin tocar datos ni lógica.

## Restricciones (invariantes)

- **No** se modifica texto mostrado, campos de formulario, validaciones, llamadas a
  repositorios/endpoints, rutas ni la estructura de navegación (Drawer).
- **No** se agregan elementos visuales que representen datos inexistentes.
- Los nombres/marca siguen siendo los de la app (UniValle/AppUnivalle), no
  "Scholarly Monolith".
- Cambios contenidos en la capa de presentación (`presentation/`) + `core/theme` +
  `core/widgets`. No se tocan `data/` ni `application/` (salvo que un restyle exija
  un getter de presentación trivial, que se evita).

## Dependencia nueva

- `google_fonts` (tipografía Inter). Si causara problemas de resolución o de carga,
  alternativa: empaquetar `Inter` como asset y declararlo en `pubspec.yaml`.

## Tests / verificación

- Lo visual no altera la lógica: la batería actual (`flutter test`) debe seguir en
  verde sin cambios.
- `flutter analyze` sin errores tras cada pase (solo los `info` intencionales
  conocidos).
- Verificación visual en el teléfono por el usuario tras el primer pase
  (Home + Formulario) antes de extender al resto.

## Criterios de aceptación

1. Existe un tema centralizado (`AppTheme`) con la paleta carmesí, superficies
   cálidas e Inter; `app.dart` lo usa.
2. Existen los 4 componentes reutilizables (`HeroHeader`, `BrandCard`,
   `SectionHeader`, `PrimaryButton`/`SecondaryButton`).
3. Home y Formulario lucen con el nuevo estilo, mostrando exactamente la misma
   información y con la misma funcionalidad/navegación que antes.
4. `flutter analyze` sin errores; `flutter test` en verde (sin cambios de tests por
   lógica).
5. Ningún dato/elemento inventado aparece en la UI.

## Fuera de alcance

- Cambios de navegación (bottom nav), de contenido o de comportamiento.
- Animaciones complejas o microinteracciones (se puede iterar después).
- Las pantallas de roles no-estudiante (la app es solo estudiante).
- Mejoras de rendimiento de carga (se trató aparte; pendiente para después).
