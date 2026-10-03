import 'package:flutter/material.dart';

/// Semantic Theme Colors for Light and Dark Modes
class AppColors {
  AppColors._();

  // Primary Brand Colors (matching fintech reference #0F7B6C)
  static const Color primary = Color(0xFF0F7B6C);
  static const Color primaryDark = Color(0xFF0A584D);
  static const Color primaryLight = Color(0xFFE8F6F3);
  static const Color primarySurface = Color(0xFFF0F9F7);
  static const Color primaryGradientStart = Color(0xFF0F7B6C);
  static const Color primaryGradientEnd = Color(0xFF136458);

  // Light Mode Background & Surfaces
  static const Color backgroundLight = Color(0xFFF7F8F6);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2EE);
  static const Color borderLight = Color(0xFFEAECE8);
  static const Color dividerLight = Color(0xFFEFEFEF);

  // Dark Mode Background & Surfaces (Modern OLED/Charcoal fintech palette)
  static const Color backgroundDark = Color(0xFF121413);
  static const Color cardDark = Color(0xFF1C1F1E);
  static const Color surfaceVariantDark = Color(0xFF262B29);
  static const Color borderDark = Color(0xFF2E3432);
  static const Color dividerDark = Color(0xFF262A29);

  // Default aliases (for backward compatibility)
  static const Color background = backgroundLight;
  static const Color card = cardLight;
  static const Color surfaceVariant = surfaceVariantLight;
  static const Color border = borderLight;
  static const Color divider = dividerLight;

  // Typography - Light Mode
  static const Color textPrimaryLight = Color(0xFF161918);
  static const Color textSecondaryLight = Color(0xFF7B827E);
  static const Color textTertiaryLight = Color(0xFFA5ACA7);

  // Typography - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF2F4F3);
  static const Color textSecondaryDark = Color(0xFF9CA39F);
  static const Color textTertiaryDark = Color(0xFF6B726F);

  // Default Typography aliases
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textTertiary = textTertiaryLight;
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);

  // Financial States
  static const Color income = Color(0xFF16A34A);
  static const Color incomeLight = Color(0xFFDCFCE7);
  static const Color incomeDarkBg = Color(0xFF133822);

  static const Color expense = Color(0xFFDC2626);
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color expenseDarkBg = Color(0xFF3B1818);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDarkBg = Color(0xFF382508);

  // Debt System Colors
  static const Color borrowed = Color(0xFFDC2626); // Red: borrowed from someone (liability)
  static const Color borrowedLight = Color(0xFFFEE2E2);
  static const Color lent = Color(0xFF16A34A);     // Green: lent to someone (asset)
  static const Color lentLight = Color(0xFFDCFCE7);

  // Category Colors
  static const Color food = Color(0xFFF97316);
  static const Color foodBg = Color(0xFFFFF3E0);

  static const Color transport = Color(0xFF0284C7);
  static const Color transportBg = Color(0xFFE0F2FE);

  static const Color home = Color(0xFF10B981);
  static const Color homeBg = Color(0xFFDCFCE7);

  static const Color education = Color(0xFF8B5CF6);
  static const Color educationBg = Color(0xFFF3E8FF);

  static const Color health = Color(0xFFEC4899);
  static const Color healthBg = Color(0xFFFCE7F3);

  static const Color clothes = Color(0xFF6366F1);
  static const Color clothesBg = Color(0xFFE0E7FF);

  static const Color entertainment = Color(0xFF06B6D4);
  static const Color entertainmentBg = Color(0xFFE0F7FA);

  static const Color other = Color(0xFF64748B);
  static const Color otherBg = Color(0xFFF1F5F9);

  // Chart Colors
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartTeal = Color(0xFF0F7B6C);
  static const Color chartBlue = Color(0xFF38BDF8);
  static const Color chartOrange = Color(0xFFFB923C);
  static const Color chartPurple = Color(0xFFA78BFA);
  static const Color chartBarInactiveLight = Color(0xFFE2E8DF);
  static const Color chartBarInactiveDark = Color(0xFF2C3330);
  static const Color chartBarInactive = chartBarInactiveLight;
}

/// Theme Extension for custom fintech semantic colors
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color background;
  final Color card;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color expenseBg;
  final Color borrowed;
  final Color borrowedBg;
  final Color lent;
  final Color lentBg;
  final Color chartInactive;

  const AppThemeTokens({
    required this.background,
    required this.card,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.expenseBg,
    required this.borrowed,
    required this.borrowedBg,
    required this.lent,
    required this.lentBg,
    required this.chartInactive,
  });

  static const light = AppThemeTokens(
    background: AppColors.backgroundLight,
    card: AppColors.cardLight,
    surfaceVariant: AppColors.surfaceVariantLight,
    border: AppColors.borderLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    income: AppColors.income,
    incomeBg: AppColors.incomeLight,
    expense: AppColors.expense,
    expenseBg: AppColors.expenseLight,
    borrowed: AppColors.borrowed,
    borrowedBg: AppColors.borrowedLight,
    lent: AppColors.lent,
    lentBg: AppColors.lentLight,
    chartInactive: AppColors.chartBarInactiveLight,
  );

  static const dark = AppThemeTokens(
    background: AppColors.backgroundDark,
    card: AppColors.cardDark,
    surfaceVariant: AppColors.surfaceVariantDark,
    border: AppColors.borderDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    income: Color(0xFF22C55E),
    incomeBg: AppColors.incomeDarkBg,
    expense: Color(0xFFF87171),
    expenseBg: AppColors.expenseDarkBg,
    borrowed: Color(0xFFF87171),
    borrowedBg: AppColors.borrowedLight,
    lent: Color(0xFF22C55E),
    lentBg: AppColors.lentLight,
    chartInactive: AppColors.chartBarInactiveDark,
  );

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? card,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? income,
    Color? incomeBg,
    Color? expense,
    Color? expenseBg,
    Color? borrowed,
    Color? borrowedBg,
    Color? lent,
    Color? lentBg,
    Color? chartInactive,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      card: card ?? this.card,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      income: income ?? this.income,
      incomeBg: incomeBg ?? this.incomeBg,
      expense: expense ?? this.expense,
      expenseBg: expenseBg ?? this.expenseBg,
      borrowed: borrowed ?? this.borrowed,
      borrowedBg: borrowedBg ?? this.borrowedBg,
      lent: lent ?? this.lent,
      lentBg: lentBg ?? this.lentBg,
      chartInactive: chartInactive ?? this.chartInactive,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeBg: Color.lerp(incomeBg, other.incomeBg, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseBg: Color.lerp(expenseBg, other.expenseBg, t)!,
      borrowed: Color.lerp(borrowed, other.borrowed, t)!,
      borrowedBg: Color.lerp(borrowedBg, other.borrowedBg, t)!,
      lent: Color.lerp(lent, other.lent, t)!,
      lentBg: Color.lerp(lentBg, other.lentBg, t)!,
      chartInactive: Color.lerp(chartInactive, other.chartInactive, t)!,
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  AppThemeTokens get appColors =>
      Theme.of(this).extension<AppThemeTokens>() ?? AppThemeTokens.light;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
