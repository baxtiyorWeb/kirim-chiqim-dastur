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
    final colors = context.appColors;

    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.recentExpenses,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticUtil.selection();
                  onViewAll?.call();
                },
                child: Row(
                  children: [
                    Text(
                      AppStrings.viewAll,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: colors.textSecondary,
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
              color: colors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
              border: Border.all(color: colors.border),
            ),
            child: recent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Hozircha xarajat yo\'q',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => Divider(
                      color: colors.border,
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${category.name} • ${DateFormatter.formatRelativeTime(item.dateTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          '${item.isExpense ? '-' : '+ '}${CurrencyFormatter.format(item.amount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: item.isExpense ? colors.textPrimary : colors.income,
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
