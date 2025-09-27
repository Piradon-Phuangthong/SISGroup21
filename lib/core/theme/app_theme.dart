import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/core/theme/color_palette.dart';

class OmadaTheme {
  OmadaTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: OmadaTokens.font2xl,
        fontWeight: OmadaTokens.weightBold,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: OmadaTokens.fontXl,
        fontWeight: OmadaTokens.weightSemibold,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: OmadaTokens.fontMd,
        fontWeight: OmadaTokens.weightRegular,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: OmadaTokens.fontSm,
      ),
    );
    // Catppuccin Latte
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: const Color(0xFF1E66F5), // Blue
        secondary: const Color(0xFF8839EF), // Mauve
        error: const Color(0xFFD20F39),
        background: const Color(0xFFE6E9EF), // Base
        surface: const Color(0xFFEFF1F5), // Mantle
        onBackground: const Color(0xFF4C4F69),
        onSurface: const Color(0xFF4C4F69),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppPaletteTheme(colors: catppuccinLatteAccents),
      ],
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E66F5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmadaTokens.space16,
          vertical: OmadaTokens.space12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space16,
            horizontal: OmadaTokens.space20,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: OmadaTokens.radius12,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space12,
            horizontal: OmadaTokens.space16,
          ),
          textStyle: TextStyle(
            fontSize: OmadaTokens.fontMd,
            fontWeight: OmadaTokens.weightSemibold,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: OmadaTokens.radius12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space8,
            horizontal: OmadaTokens.space12,
          ),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(borderRadius: OmadaTokens.radius12),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(
          horizontal: OmadaTokens.space8,
          vertical: OmadaTokens.space4,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: OmadaTokens.font2xl,
        fontWeight: OmadaTokens.weightBold,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: OmadaTokens.fontXl,
        fontWeight: OmadaTokens.weightSemibold,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: OmadaTokens.fontMd,
        fontWeight: OmadaTokens.weightRegular,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: OmadaTokens.fontSm,
      ),
    );
    // Catppuccin Mocha
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFF89B4FA),
        secondary: const Color(0xFFCBA6F7),
        error: const Color(0xFFF38BA8),
        background: const Color(0xFF1E1E2E), // Base
        surface: const Color(0xFF181825), // Mantle
        onBackground: const Color(0xFFCDD6F4), // Text
        onSurface: const Color(0xFFCDD6F4),
        onPrimary: const Color(0xFF11111B),
        onSecondary: const Color(0xFF11111B),
        onError: const Color(0xFF11111B),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppPaletteTheme(colors: catppuccinMochaAccents),
      ],
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF181825),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmadaTokens.space16,
          vertical: OmadaTokens.space12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space16,
            horizontal: OmadaTokens.space20,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: OmadaTokens.radius12,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space12,
            horizontal: OmadaTokens.space16,
          ),
          textStyle: TextStyle(
            fontSize: OmadaTokens.fontMd,
            fontWeight: OmadaTokens.weightSemibold,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: OmadaTokens.radius12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: OmadaTokens.space8,
            horizontal: OmadaTokens.space12,
          ),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        shape: const RoundedRectangleBorder(borderRadius: OmadaTokens.radius12),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(
          horizontal: OmadaTokens.space8,
          vertical: OmadaTokens.space4,
        ),
      ),
    );
  }
}

class AppPaletteTheme extends ThemeExtension<AppPaletteTheme> {
  final List<Color> colors;

  const AppPaletteTheme({required this.colors});

  Color colorForIndex(int index) => colors[index % colors.length];

  Color colorForId(String id) {
    final hash = id.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  AppPaletteTheme copyWith({List<Color>? colors}) {
    return AppPaletteTheme(colors: colors ?? this.colors);
  }

  @override
  AppPaletteTheme lerp(ThemeExtension<AppPaletteTheme>? other, double t) {
    if (other is! AppPaletteTheme) return this;
    final int maxLen = colors.length > other.colors.length
        ? colors.length
        : other.colors.length;
    final List<Color> blended = List<Color>.generate(maxLen, (i) {
      final a = colors[i % colors.length];
      final b = other.colors[i % other.colors.length];
      return Color.lerp(a, b, t) ?? a;
    });
    return AppPaletteTheme(colors: blended);
  }
}
