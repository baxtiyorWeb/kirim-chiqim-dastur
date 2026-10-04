import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/haptic_feedback_util.dart';
import '../models/financial_health.dart';
import '../providers/financial_intelligence_provider.dart';

/// Oddiy foydalanuvchiga tushunarli "Olsam bo'ladimi?" (Xaridni tekshirish) modali
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
  bool _decisionRecorded = false;

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
    _tryRecordDecision();
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean) ?? 0;
    setState(() {
      _currentAmount = parsed;
    });
    if (parsed > 0) {
      _tryRecordDecision();
    }
  }

  void _tryRecordDecision() {
    if (!_decisionRecorded && _currentAmount > 0) {
      _decisionRecorded = true;
      ref.read(evaluatedDecisionsCountProvider.notifier).recordDecision();
    }
  }

  String _getEmojiForRisk(FinancialRiskLevel level) {
    switch (level) {
      case FinancialRiskLevel.safe:
        return '🟢';
      case FinancialRiskLevel.caution:
        return '🟡';
      case FinancialRiskLevel.danger:
        return '🔴';
    }
  }

  void _shareResult(WhatIfResult result) {
    HapticUtil.selection();
    final text = '${CurrencyFormatter.format(result.scenarioAmount)} xaridni tekshirdim:\n'
        '• Xulosa: ${_getEmojiForRisk(result.riskLevel)} ${result.impactBadge}\n'
        '• Qoladigan pulim: ${CurrencyFormatter.format(result.currentBalance)} ➔ ${CurrencyFormatter.format(result.postBalance)}\n'
        '• Kunlik xarajatim: ${CurrencyFormatter.format(result.currentSafeToSpendToday)} ➔ ${CurrencyFormatter.format(result.postSafeToSpendToday)}/kun\n\n'
        'The Go-Getters ilovasida oldindan hisoblandi.';

    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xulosa nusxalandi'),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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

            // Sarlavha: Oddiy va insoniy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
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
                        'Olsam bo\'ladimi?',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Xarid summasini kiriting, ilova cho\'ntagingizga qarab maslahat beradi',
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

            // Summa kiritish
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onAmountChanged,
              autofocus: true,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Xarid summasi',
                labelStyle: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.4),
                  fontSize: 17,
                ),
                suffixText: 'so\'m',
                suffixStyle: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
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

            // Oson tanlash tugmalari
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildPresetChip('50 ming', 50000),
                  const SizedBox(width: 8),
                  _buildPresetChip('100 ming', 100000),
                  const SizedBox(width: 8),
                  _buildPresetChip('300 ming', 300000),
                  const SizedBox(width: 8),
                  _buildPresetChip('500 ming', 500000),
                  const SizedBox(width: 8),
                  _buildPresetChip('1 mln', 1000000),
                  const SizedBox(width: 8),
                  _buildPresetChip('2 mln', 2000000),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Natija kartasi
            if (_currentAmount > 0) ...[
              // 1. Katta va tushunarli Xulosa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: _getResultBgColor(result.riskLevel, isDark),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: _getResultBorderColor(result.riskLevel).withValues(alpha: 0.5),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_getEmojiForRisk(result.riskLevel), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.impactBadge,
                            style: TextStyle(
                              color: _getResultBorderColor(result.riskLevel),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.consequenceMessage,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // 2. Cho'ntakka ta'siri (Keng va qulay kartalar)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cho\'ntakka ta\'siri:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Qoladigan pul kartasi
                  _buildImpactMetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Qoladigan pulingiz',
                    before: CurrencyFormatter.format(result.currentBalance),
                    after: CurrencyFormatter.format(result.postBalance),
                    afterColor: result.postBalance >= 0 ? colors.textPrimary : Colors.red,
                    colors: colors,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  // Kunlik me'yor kartasi
                  _buildImpactMetricCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Har kungi me\'yoringiz',
                    before: '${CurrencyFormatter.format(result.currentSafeToSpendToday)}/kun',
                    after: '${CurrencyFormatter.format(result.postSafeToSpendToday)}/kun',
                    afterColor: result.isSafe ? const Color(0xFF10B981) : Colors.amber.shade700,
                    colors: colors,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space12),

              // 3. Maslahat (Tavsiya)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.adviceMessage,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textPrimary,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // PRO tafsilot havolasi
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/pricing');
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Keyingi 30 kunlik batafsil tahlilni ko\'rish',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),
            ] else ...[
              // Bo'sh holatdagi tushunarli yo'riqnoma
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191C22) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛍️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Masalan, kiyim, telefon yoki kutilmagan xarid summasini kiriting. Ilova oylik pulingiz va har kungi sarfingizga qarab xolis maslahat beradi.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Harakat tugmalari
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
      ),
    );
  }

  Widget _buildImpactMetricCard({
    required IconData icon,
    required String label,
    required String before,
    required String after,
    required Color afterColor,
    required dynamic colors,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191C22) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Oldingi holat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oldin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    before,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // O'tish belgisi
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF232730) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: colors.textSecondary,
                ),
              ),

              // Yangi holat
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Xariddan keyin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    after,
                    style: TextStyle(
                      color: afterColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
}
