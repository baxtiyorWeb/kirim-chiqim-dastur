import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/guide/guide.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../core/widgets/initial_balance_dialog.dart';
import '../../../providers/finance_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isPro = ref.watch(proMemberProvider);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.navProfile,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userProfileProvider.notifier).refresh();
          await ref.read(dashboardSummaryProvider.notifier).refresh();
          await ref.read(subscriptionProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
          children: [
            const SizedBox(height: AppDimensions.space12),

            // User Info Card (Clickable to Edit Profile)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticUtil.selection();
                  context.push('/edit-profile');
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/user_avatar.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.person, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppDimensions.space16),

                      // Name & Plan Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (ref.watch(userProfileProvider).fullName.isNotEmpty &&
                                      ref.watch(userProfileProvider).fullName != 'Foydalanuvchi')
                                  ? ref.watch(userProfileProvider).fullName
                                  : (ref.watch(financeRepositoryProvider).currentUserName ??
                                      AppStrings.userFullName),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPro ? const Color(0xFF007A55) : colors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  ),
                                  child: Text(
                                    isPro ? 'Pro Intellekt ⭐' : AppStrings.freePlan,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isPro ? Colors.white : colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tahrirlash',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Balance Card with edit action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.totalBalance,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _editInitialBalanceDialog(context, ref),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (ref.watch(initialBalanceProvider) > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Boshlang\'ich kiritilgan: ${CurrencyFormatter.format(ref.watch(initialBalanceProvider))}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Pricing & Subscription Promo Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticUtil.selection();
                  context.push('/pricing');
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F2B1D), const Color(0xFF13221C)]
                          : [const Color(0xFFE8F8F0), const Color(0xFFF0FDF4)],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                    border: Border.all(
                      color: const Color(0xFF007A55).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isPro ? 'Pro Intellekt Faol' : 'Ta\'rif rejalari (Pro / Bepul)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF007A55),
                                  ),
                                ),
                                if (!isPro) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Builder(builder: (context) {
                              final subState = ref.watch(subscriptionProvider);
                              final exp = subState.subscription.currentPeriodEnd;
                              if (isPro && exp != null) {
                                return Text(
                                  'Amal qilish muddati: ${exp.day}.${exp.month.toString().padLeft(2, '0')}.${exp.year}',
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                );
                              }
                              return Text(
                                isPro
                                    ? 'Ta\'rifni boshqarish yoki imtiyozlarni ko\'rish'
                                    : 'Xarid hisobi va oylik tahlillar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF007A55),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Group 1 Menu Options (Goals, Smeta, Debts, Reports)

            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _menuTile(
                    context: context,
                    icon: Icons.track_changes_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: AppStrings.goals,
                    subtitle: AppStrings.goalsSubtitle,
                    onTap: () {
                      HapticUtil.selection();
                      context.push('/goals');
                    },
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.pie_chart_outline_rounded,
                    iconColor: AppColors.transport,
                    iconBg: AppColors.transportBg,
                    title: AppStrings.budget,
                    subtitle: AppStrings.budgetSubtitle,
                    onTap: () {
                      HapticUtil.selection();
                      context.push('/budget');
                    },
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.swap_horiz_rounded,
                    iconColor: AppColors.food,
                    iconBg: AppColors.foodBg,
                    title: AppStrings.debts,
                    subtitle: AppStrings.debtsSubtitle,
                    onTap: () {
                      HapticUtil.selection();
                      context.push('/debts');
                    },
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.description_outlined,
                    iconColor: AppColors.education,
                    iconBg: AppColors.educationBg,
                    title: AppStrings.reports,
                    subtitle: AppStrings.reportsSubtitle,
                    onTap: () {
                      HapticUtil.selection();
                      showExportBottomSheet(context, ref);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Group 2 Menu Options (Settings, Theme, Support, Rate)
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _menuTile(
                    context: context,
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'Mavzu (Tungi rejim)',
                    subtitle: themeMode == ThemeMode.dark
                        ? 'Tungi rejim'
                        : (themeMode == ThemeMode.light ? 'Kunduzgi rejim' : 'Tizim bo\'yicha'),
                    onTap: () => _showThemeModeSheet(context, ref),
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.other,
                    iconBg: AppColors.otherBg,
                    title: AppStrings.helpSupport,
                    subtitle: 'Savollar va yordam',
                    onTap: () {
                      HapticUtil.selection();
                      showSupportBottomSheet(context);
                    },
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.explore_outlined,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'Ilova bo‘yicha qo‘llanma',
                    subtitle: 'Qo‘llanmani qaytadan ko‘rish',
                    onTap: () {
                      HapticUtil.selection();
                      ref.read(guideControllerProvider.notifier).startTour(
                        AppTours.firstLaunchTour,
                        force: true,
                      );
                      context.go('/dashboard');
                    },
                  ),
                  Divider(color: colors.border, height: 1, indent: 64),
                  _menuTile(
                    context: context,
                    icon: Icons.delete_forever_outlined,
                    iconColor: colors.expense,
                    iconBg: colors.expenseBg,
                    title: 'Hisob ma\'lumotlarini o\'chirish',
                    titleColor: colors.expense,
                    onTap: () => _handleDeleteAccount(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Logout Button with Confirmation
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _menuTile(
                context: context,
                icon: Icons.logout_rounded,
                iconColor: colors.expense,
                iconBg: colors.expenseBg,
                title: AppStrings.logout,
                titleColor: colors.expense,
                showArrow: false,
                onTap: () async {
                  final confirmed = await showConfirmSheet(
                    context: context,
                    title: 'Hisobdan chiqmoqchimisiz?',
                    message: 'Chiqsangiz keyin yana xavfsiz qayta kirishingiz mumkin bo\'ladi.',
                    confirmLabel: 'Chiqish',
                    cancelLabel: 'Bekor qilish',
                    isDestructive: false,
                    icon: Icons.logout_rounded,
                    onConfirm: () async {
                      HapticUtil.medium();
                      await appLogout(ref);
                    },
                  );
                  if (confirmed == true) {
                    await appLogout(ref);
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );
}

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Color? titleColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? colors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            )
          : null,
      trailing: showArrow
          ? Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            )
          : null,
    );
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mavzuni tanlang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _themeOptionTile(
                context: ctx,
                title: 'Kunduzgi rejim (Yorug\')',
                subtitle: 'Klassik toza yorug\' dizayn',
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFFE5A100),
                iconBg: const Color(0xFFFFF7E6),
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  HapticUtil.selection();
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _themeOptionTile(
                context: ctx,
                title: 'Tungi rejim (Qorong\'i)',
                subtitle: 'Ko\'zga qulay zamonaviy qorong\'i interfeys',
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEEF2FF),
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  HapticUtil.selection();
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _themeOptionTile(
                context: ctx,
                title: 'Tizim sozlamalari bo\'yicha',
                subtitle: 'Qurilma rejimiga mos avtomatik almashtirish',
                icon: Icons.brightness_auto_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primaryLight,
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  HapticUtil.selection();
                  ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: isSelected ? AppColors.primary : colors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editInitialBalanceDialog(BuildContext context, WidgetRef ref) {
    showInitialBalanceDialog(context, ref);
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Barcha ma\'lumotlarni o\'chirish',
      message: 'DIQQAT: Barcha kiritilgan xarajatlar, daromadlar, qarzlar daftari va byudjet butunlay o\'chiriladi. Bu amalni ortga qaytarib bo\'lmaydi!',
      confirmLabel: 'Ha, butunlay o\'chirilsin',
      cancelLabel: 'Bekor qilish',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
      onConfirm: () async {
        await appLogout(ref);
        HapticUtil.heavy();
      },
    );

    if (confirmed == true && context.mounted) {
      context.go('/onboarding');
    }
  }
}
