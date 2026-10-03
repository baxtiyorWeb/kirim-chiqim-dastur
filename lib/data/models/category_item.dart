import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum TransactionType { expense, income }

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final TransactionType type;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.type = TransactionType.expense,
  });

  static const List<CategoryItem> defaultExpenseCategories = [
    CategoryItem(
      id: 'food',
      name: 'Ovqatlanish',
      icon: Icons.restaurant_rounded,
      iconColor: AppColors.food,
      backgroundColor: AppColors.foodBg,
    ),
    CategoryItem(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      iconColor: AppColors.transport,
      backgroundColor: AppColors.transportBg,
    ),
    CategoryItem(
      id: 'home',
      name: 'Uy-joy',
      icon: Icons.home_rounded,
      iconColor: AppColors.home,
      backgroundColor: AppColors.homeBg,
    ),
    CategoryItem(
      id: 'education',
      name: 'Ta\'lim',
      icon: Icons.school_rounded,
      iconColor: AppColors.education,
      backgroundColor: AppColors.educationBg,
    ),
    CategoryItem(
      id: 'health',
      name: 'Salomatlik',
      icon: Icons.favorite_rounded,
      iconColor: AppColors.health,
      backgroundColor: AppColors.healthBg,
    ),
    CategoryItem(
      id: 'clothes',
      name: 'Kiyim',
      icon: Icons.checkroom_rounded,
      iconColor: AppColors.clothes,
      backgroundColor: AppColors.clothesBg,
    ),
    CategoryItem(
      id: 'entertainment',
      name: 'Ko\'ngilochar',
      icon: Icons.sports_esports_rounded,
      iconColor: AppColors.entertainment,
      backgroundColor: AppColors.entertainmentBg,
    ),
    CategoryItem(
      id: 'other',
      name: 'Boshqa',
      icon: Icons.more_horiz_rounded,
      iconColor: AppColors.other,
      backgroundColor: AppColors.otherBg,
    ),
  ];

  static const List<CategoryItem> defaultIncomeCategories = [
    CategoryItem(
      id: 'salary',
      name: 'Maosh',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.income,
      backgroundColor: AppColors.incomeLight,
      type: TransactionType.income,
    ),
    CategoryItem(
      id: 'business',
      name: 'Biznes',
      icon: Icons.business_center_rounded,
      iconColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      type: TransactionType.income,
    ),
    CategoryItem(
      id: 'bonus',
      name: 'Mukofot',
      icon: Icons.card_giftcard_rounded,
      iconColor: AppColors.food,
      backgroundColor: AppColors.foodBg,
      type: TransactionType.income,
    ),
    CategoryItem(
      id: 'investment',
      name: 'Investitsiya',
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.transport,
      backgroundColor: AppColors.transportBg,
      type: TransactionType.income,
    ),
    CategoryItem(
      id: 'other_income',
      name: 'Boshqa daromad',
      icon: Icons.attach_money_rounded,
      iconColor: AppColors.other,
      backgroundColor: AppColors.otherBg,
      type: TransactionType.income,
    ),
  ];

  static CategoryItem getById(String id) {
    for (final c in defaultExpenseCategories) {
      if (c.id == id) return c;
    }
    for (final c in defaultIncomeCategories) {
      if (c.id == id) return c;
    }
    return defaultExpenseCategories.last;
  }
}
