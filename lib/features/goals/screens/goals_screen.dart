import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../data/models/savings_goal.dart';
import '../../../providers/finance_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Maqsadlar va Jamg\'arma',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Maqsad qo\'shish', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(goalsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
          children: [
            const SizedBox(height: AppDimensions.space12),

            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Hozircha maqsadlar belgilanmagan',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final percent = (goal.progressPercentage * 100).toInt();

                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  goal.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Animated Linear Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: goal.progressPercentage),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, val, child) {
                              return LinearProgressIndicator(
                                value: val,
                                minHeight: 8,
                                backgroundColor: colors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action to add deposit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              goal.isCompleted
                                  ? '🎉 Maqsadga erishildi!'
                                  : 'Qoldi: ${CurrencyFormatter.format(goal.remainingAmount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: goal.isCompleted ? colors.income : colors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                if (!goal.isCompleted) ...[
                                  TextButton.icon(
                                    onPressed: () => _addDepositDialog(context, ref, goal),
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                    label: const Text('Mablag\' qo\'shish', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.textTertiary),
                                  tooltip: 'Maqsadni o\'chirish',
                                  onPressed: () async {
                                    final confirm = await showConfirmSheet(
                                      context: context,
                                      title: 'Maqsadni o\'chirish',
                                      message: '"${goal.title}" maqsadi butunlay o\'chiriladi. Rozimisiz?',
                                      confirmLabel: 'O\'chirish',
                                      isDestructive: true,
                                      icon: Icons.delete_outline_rounded,
                                    );
                                    if (confirm == true) {
                                      HapticUtil.medium();
                                      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Maqsad o\'chirildi'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );
}

  void _addDepositDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final controller = TextEditingController();
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${goal.title} ga mablag\' qo\'shish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Qo\'shiladigan summa',
                  suffixText: 'so\'m',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt = CurrencyFormatter.parse(controller.text);
                    if (amt > 0) {
                      try {
                        await ref.read(goalsProvider.notifier).addDeposit(goal.id, amt);
                        if (ctx.mounted) Navigator.pop(ctx);
                        HapticUtil.success();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jamg\'armaga muvaffaqiyatli qo\'shildi'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Xatolik: $e'),
                              backgroundColor: colors.expense,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yangi jamg\'arma maqsadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Maqsad nomi (Masalan: Avtomobil)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kerakli summa (so\'m)', suffixText: 'so\'m'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amt = CurrencyFormatter.parse(amountController.text);
                    if (title.isNotEmpty && amt > 0) {
                      final newGoal = SavingsGoal(
                        id: const Uuid().v4(),
                        title: title,
                        targetAmount: amt,
                        currentAmount: 0,
                        emoji: '🚀',
                      );
                      try {
                        await ref.read(goalsProvider.notifier).addGoal(newGoal);
                        if (ctx.mounted) Navigator.pop(ctx);
                        HapticUtil.success();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Yangi maqsad yaratildi'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Xatolik: $e'),
                              backgroundColor: colors.expense,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Yaratish', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
