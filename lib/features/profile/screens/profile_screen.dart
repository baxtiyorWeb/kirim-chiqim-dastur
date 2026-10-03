import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/finance_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.navProfile,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.space12),

            // User Info Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
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
                        const Text(
                          AppStrings.userFullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: const Text(
                            AppStrings.freePlan,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.totalBalance,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Group 1 Menu Options
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _menuTile(
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
                  const Divider(color: AppColors.borderLight, height: 1, indent: 64),
                  _menuTile(
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
                  const Divider(color: AppColors.borderLight, height: 1, indent: 64),
                  _menuTile(
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
                  const Divider(color: AppColors.borderLight, height: 1, indent: 64),
                  _menuTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.education,
                    iconBg: AppColors.educationBg,
                    title: AppStrings.reports,
                    subtitle: AppStrings.reportsSubtitle,
                    onTap: () {
                      HapticUtil.selection();
                      _showExportDialog(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Group 2 Menu Options
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _menuTile(
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.other,
                    iconBg: AppColors.otherBg,
                    title: AppStrings.settings,
                    onTap: () => _showSettingsDialog(context),
                  ),
                  const Divider(color: AppColors.borderLight, height: 1, indent: 64),
                  _menuTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.other,
                    iconBg: AppColors.otherBg,
                    title: AppStrings.helpSupport,
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.borderLight, height: 1, indent: 64),
                  _menuTile(
                    icon: Icons.star_border_rounded,
                    iconColor: AppColors.other,
                    iconBg: AppColors.otherBg,
                    title: AppStrings.rateApp,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Logout Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: _menuTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.expense,
                iconBg: AppColors.expenseLight,
                title: AppStrings.logout,
                titleColor: AppColors.expense,
                showArrow: false,
                onTap: () {
                  HapticUtil.medium();
                  context.go('/onboarding');
                },
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Color? titleColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
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
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            )
          : null,
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: const Text('Hisobotni eksport qilish'),
          content: const Text(
            'Barcha xarajatlar va daromadlar hisobotini PDF yoki Excel formatida saqlab olishingiz mumkin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Excel (.xlsx)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF hisobot yuklab olindi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('PDF yuklash'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sozlamalar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Asosiy valyuta'),
                  trailing: const Text('UZS (so\'m)', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tungi rejim'),
                  trailing: const Text('O\'chirilgan', style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Til'),
                  trailing: const Text('O\'zbekcha', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
