## Omada Design System

This app uses a lightweight design system to keep UI consistent across pages.

### Tokens
- Spacing: `OmadaTokens.space{2,4,6,8,12,16,20,24,32,40,48}`
- Radius: `OmadaTokens.radius{4,8,12,16}`
- Durations: `OmadaTokens.{fast,normal,slow}`
- Shadows: `OmadaTokens.{shadowSm,shadowMd,shadowLg}`
- Typography: sizes `font{Xs,Sm,Md,Lg,Xl,2xl,3xl,4xl}`, weights `weight{Regular,Medium,Semibold,Bold}`
- Icons: `icon{Sm,Md,Lg,Xl}`
- Semantic colors: `color{Success,Warning,Error,Info}`

### Theme
- `OmadaTheme.light()` and `OmadaTheme.dark()` set component themes (AppBar, Inputs, Buttons, Chips, Cards) and a consistent text scale.
- Wired in `MaterialApp` via `theme`, `darkTheme`, `themeMode` in `lib/main.dart`.
- Palette is exposed via `AppPaletteTheme` (ThemeExtension). Access with:
  - `Theme.of(context).extension<AppPaletteTheme>()?.colorForId(id)`
  - Prefer this over importing `appPalette` directly in widgets.

### Primitives
- `AppCard`: standard container with radius, shadow, and padding.
- `AppTagChip`: compact colored tag chip used for contact tags.
- `AppScaffold`: page wrapper with SafeArea and horizontal padding.

### Usage Guidelines
- Prefer tokens for spacing, sizes, and radii instead of raw numbers.
- Use themed components (`ElevatedButton`, `FilledButton`, etc.) without local overrides unless necessary.
- Use `Theme.of(context).textTheme` for text. Avoid hard-coded text styles.

### Where Used
- Pages: contacts, login, splash, contact form, account, profile.
- Widgets: app bar, bottom nav, filter row, tag chips, sheets.

## Migration checklist (for new/updated UI)

- Spacing/sizes use `OmadaTokens` (e.g., `space16`, `radius12`, `iconMd`). No magic numbers.
- Text uses `Theme.of(context).textTheme` (avoid inline TextStyle when possible).
- Colors use `Theme.of(context).colorScheme` and palette via `AppPaletteTheme`:
  - `Theme.of(context).extension<AppPaletteTheme>()?.colorForId(id)` for colored chips/avatars.
  - Do not hard-code hex colors in widgets.
- Prefer DS primitives: `AppCard`, `AppTagChip`, `AppScaffold`.
- Inputs/buttons rely on themed components (no local styling unless needed).
- Remove any dependencies on theme selection widgets; single palette is app-wide.
- Update relevant READMEs when adding new widgets/pages.


