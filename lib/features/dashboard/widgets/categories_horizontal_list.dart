import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/models/category_item.dart';

class CategoriesHorizontalList extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final VoidCallback? onViewAll;
  final Function(CategoryItem)? onCategoryTap;

  const CategoriesHorizontalList({
    super.key,
    required this.categoryExpenses,
    this.onViewAll,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final categories = CategoryItem.defaultExpenseCategories;

    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.categories,
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

        // Horizontal Category Cards
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final expense = categoryExpenses[cat.id] ?? 0.0;

              return _CategoryCard(
                category: cat,
                amount: expense,
                onTap: () {
                  HapticUtil.selection();
                  onCategoryTap?.call(cat);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final double amount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in tinted circular container
            Container(
              width: 38,
              height: 38,
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

            const SizedBox(height: 8),

            // Category Name
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 2),

            // Amount (e.g. "520 000")
            Text(
              CurrencyFormatter.format(amount, includeSymbol: false),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
