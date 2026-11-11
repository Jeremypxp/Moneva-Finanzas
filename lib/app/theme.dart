import 'package:flutter/material.dart';

/// Colores semánticos propios de la app (ingresos, gastos y acentos).
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.incomeSoft,
    required this.expenseSoft,
    required this.heroStart,
    required this.heroEnd,
    required this.mutedText,
  });

  final Color income;
  final Color expense;
  final Color incomeSoft;
  final Color expenseSoft;
  final Color heroStart;
  final Color heroEnd;
  final Color mutedText;

  static const light = FinanceColors(
    income: Color(0xFF16805F),
    expense: Color(0xFFC8543A),
    incomeSoft: Color(0xFFE0F2EA),
    expenseSoft: Color(0xFFFBE7E1),
    heroStart: Color(0xFF0E5C4D),
    heroEnd: Color(0xFF17856D),
    mutedText: Color(0xFF68746F),
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? incomeSoft,
    Color? expenseSoft,
    Color? heroStart,
    Color? heroEnd,
    Color? mutedText,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) {
      return this;
    }
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

ThemeData buildAppTheme() {
  const seed = Color(0xFF146B5A);
  const background = Color(0xFFF5F5EF);
  const surface = Color(0xFFFFFFFF);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: surface,
      ).copyWith(
        primary: seed,
        onPrimary: Colors.white,
        secondary: const Color(0xFFB95E43),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF0F2EC),
        outline: const Color(0xFFD5DAD2),
        outlineVariant: const Color(0xFFE7EAE4),
      );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final textTheme = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
      height: 1.05,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F4EF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFD8EEE6),
      height: 72,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? seed : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? seed : scheme.onSurfaceVariant,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1D2925),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.all(16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    extensions: const [FinanceColors.light],
  );
}
