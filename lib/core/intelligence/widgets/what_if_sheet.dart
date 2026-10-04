import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/haptic_feedback_util.dart';
import '../models/financial_health.dart';
import '../providers/financial_intelligence_provider.dart';

/// Interactive What-If Scenario Simulator Bottom Sheet
/// Allows the user to simulate an expense before deciding to spend.
Future<void> showWhatIfSimulatorSheet(BuildContext context) {
  HapticUtil.selection();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const WhatIfSheet(),
  );
}

class WhatIfSheet extends ConsumerStatefulWidget {
  const WhatIfSheet({super.key});

  @override
  ConsumerState<WhatIfSheet> createState() => _WhatIfSheetState();
}

class _WhatIfSheetState extends ConsumerState<WhatIfSheet> {
  final TextEditingController _amountController = TextEditingController();
  int _currentAmount = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    HapticUtil.selection();
    setState(() {
      _currentAmount = amount;
      _amountController.text = CurrencyFormatter.format(amount).replaceAll(' so\'m', '');
    });
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean) ?? 0;
    setState(() {
      _currentAmount = parsed;
    });
  }

  void _shareResult(WhatIfResult result) {
    HapticUtil.selection();
    final text = 'Moliyaviy xarid hisobi xulosasi:\n'
        '• Rejalashtirilgan xarid: ${CurrencyFormatter.format(result.scenarioAmount)}\n'
        '• Xariddan so‘nggi balans: ${CurrencyFormatter.format(result.postBalance)}\n'
        '• Yangi kunlik xarajat me\'yori: ${CurrencyFormatter.format(result.postSafeToSpendToday)}/kun\n'
        '• Xulosa: ${result.consequenceMessage}\n\n'
        'The Go-Getters ilovasi orqali hisoblandi.';
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xarid hisobi xulosasi nusxalandi'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthState = ref.watch(financialIntelligenceProvider);
    final result = healthState.simulateExpense(_currentAmount);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusExtraLarge),
        ),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: AppDimensions.space16,
        left: AppDimensions.space20,
        right: AppDimensions.space20,
        bottom: MediaQuery.paddingOf(context).bottom + AppDimensions.space20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xaridni hisoblash',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Xarid qilishdan oldin oylik me\'yorga ta\'sirini tekshiring',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space16),

          // Clean Standard Form Input Field (No nested block container)
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onAmountChanged,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Xarid summasi',
              labelStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
              ),
              hintText: '0',
              hintStyle: TextStyle(
                color: colors.textSecondary.withValues(alpha: 0.4),
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.shopping_bag_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              suffixText: 'so\'m',
              suffixStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF191C22) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide(
                  color: colors.border.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space12),

          // Quick Amount Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPresetChip('+100 ming', 100000),
                const SizedBox(width: 8),
                _buildPresetChip('+300 ming', 300000),
                const SizedBox(width: 8),
                _buildPresetChip('+500 ming', 500000),
                const SizedBox(width: 8),
                _buildPresetChip('+1 mln', 1000000),
                const SizedBox(width: 8),
                _buildPresetChip('+2 mln', 2000000),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Reactive Simulation Result Card
          if (_currentAmount > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: _getResultBgColor(result.riskLevel, isDark),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: _getResultBorderColor(result.riskLevel).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getResultIcon(result.riskLevel),
                        color: _getResultBorderColor(result.riskLevel),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getResultBadgeTitle(result.riskLevel),
                        style: TextStyle(
                          color: _getResultBorderColor(result.riskLevel),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.consequenceMessage,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                  const Divider(height: 18),

                  // Metrics Comparison Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCol(
                        label: 'Yangi balans',
                        value: CurrencyFormatter.format(result.postBalance),
                        color: colors.textPrimary,
                      ),
                      _buildMetricCol(
                        label: 'Kunlik me\'yor',
                        value: '${CurrencyFormatter.format(result.postSafeToSpendToday)}/kun',
                        color: result.isSafe ? AppColors.primary : Colors.amber.shade700,
                      ),
                      _buildMetricCol(
                        label: 'Yetish muddati',
                        value: '~${result.postRunwayDays} kun',
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191C22) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Xarid summasini kiriting va uning oylik mablag\'ingizga ta\'sirini oldindan bilib oling.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
          ],

          // Action Buttons
          Row(
            children: [
              if (_currentAmount > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareResult(result),
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Ulashish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                  ),
                ),
              if (_currentAmount > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentAmount > 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticUtil.selection();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: Text(
                    _currentAmount > 0 ? 'Tushunarli' : 'Yopish',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int amount) {
    final isSelected = _currentAmount == amount;
    return GestureDetector(
      onTap: () => _setAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey.shade400,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getResultBgColor(FinancialRiskLevel level, bool isDark) {
    switch (level) {
      case FinancialRiskLevel.safe:
        return isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9);
      case FinancialRiskLevel.caution:
        return isDark ? const Color(0xFF2C2410) : const Color(0xFFFFF8E1);
      case FinancialRiskLevel.danger:
        return isDark ? const Color(0xFF2D1616) : const Color(0xFFFFEBEE);
    }
  }

  Color _getResultBorderColor(FinancialRiskLevel level) {
    switch (level) {
      case FinancialRiskLevel.safe:
        return const Color(0xFF00A86B);
      case FinancialRiskLevel.caution:
        return const Color(0xFFFFB300);
      case FinancialRiskLevel.danger:
        return const Color(0xFFE53935);
    }
  }

  IconData _getResultIcon(FinancialRiskLevel level) {
    switch (level) {
      case FinancialRiskLevel.safe:
        return Icons.check_circle_outline_rounded;
      case FinancialRiskLevel.caution:
        return Icons.warning_amber_rounded;
      case FinancialRiskLevel.danger:
        return Icons.error_outline_rounded;
    }
  }

  String _getResultBadgeTitle(FinancialRiskLevel level) {
    switch (level) {
      case FinancialRiskLevel.safe:
        return 'Xavfsiz xarid';
      case FinancialRiskLevel.caution:
        return 'Ehtiyotkorlik talab etiladi';
      case FinancialRiskLevel.danger:
        return 'Kamomad xavfi bor';
    }
  }
}
