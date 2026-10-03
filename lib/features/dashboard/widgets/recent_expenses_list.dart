import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/models/category_item.dart';
import '../../../data/models/transaction_item.dart';

class RecentExpensesList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final VoidCallback? onViewAll;
  final Function(TransactionItem)? onItemTap;

  const RecentExpensesList({
    super.key,
    required this.transactions,
    this.onViewAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(4).toList();

    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.recentExpenses,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticUtil.selection();
                  onViewAll?.call();
                },
                child: const Row(
                  children: [
                    Text(
                      AppStrings.viewAll,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space12),

        // List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.borderLight,
                height: 1,
                indent: 64,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = recent[index];
                final category = CategoryItem.getById(item.categoryId);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: 2,
                  ),
                  onTap: () {
                    HapticUtil.light();
                    onItemTap?.call(item);
                  },
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: category.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      color: category.iconColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${category.name} • ${DateFormatter.formatRelativeTime(item.dateTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(item.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
