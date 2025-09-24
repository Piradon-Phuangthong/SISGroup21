# Theme and Design Tokens

This directory defines the design system foundations and app theme wiring.

- `design_tokens.dart`: Spacing, radii, durations, shadows, icon sizes, typography sizes/weights, semantic colors.
- `color_palette.dart`: Single `appPalette` used for colorful chips/avatars.
- `app_theme.dart`: Light/Dark `ThemeData` with component themes and `AppPaletteTheme` (ThemeExtension) exposing the palette via the theme.

## Accessing Tokens

- Spacing: `OmadaTokens.space16`
- Radius: `OmadaTokens.radius12`
- Typography: `OmadaTokens.fontMd`, `OmadaTokens.weightSemibold`
- Icons: `OmadaTokens.iconMd`
- Semantic colors: `OmadaTokens.colorSuccess`, `colorWarning`, `colorError`, `colorInfo`

## Accessing Palette via Theme

```dart
final palette = Theme.of(context).extension<AppPaletteTheme>();
final Color chipColor = palette?.colorForId(model.id) ?? Theme.of(context).colorScheme.secondary;
```

Prefer reading from the ThemeExtension rather than importing `appPalette` directly inside widgets.
