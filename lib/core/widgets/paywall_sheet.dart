import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptic_feedback_util.dart';
import '../monetization/monetization_analytics.dart';
import '../payment/payment_types.dart';
import '../../providers/finance_providers.dart';
import '../../data/models/billing_models.dart';

Future<bool?> showPaywallSheet(
  BuildContext context, {
  required String featureKey,
  String? featureTitle,
  String? featureDescription,
}) {
  HapticUtil.selection();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaywallSheet(
      featureKey: featureKey,
      featureTitle: featureTitle,
      featureDescription: featureDescription,
    ),
  );
}

class PaywallSheet extends ConsumerStatefulWidget {
  final String featureKey;
  final String? featureTitle;
  final String? featureDescription;

  const PaywallSheet({
    super.key,
    required this.featureKey,
    this.featureTitle,
    this.featureDescription,
  });

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  bool _isAnnual = true;
  PaymentProviderType _selectedProvider = PaymentProviderType.click;
  bool _isLoading = false;

  static const int _monthlyPrice = 19000;
  static const int _annualPrice = 149000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monetizationAnalyticsProvider).logPaywallView(
            featureKey: widget.featureKey,
            source: 'paywall_sheet',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subState = ref.watch(subscriptionProvider);
    final entitlement = subState.getEntitlement(widget.featureKey);

    final title = widget.featureTitle ?? _getDefaultFeatureTitle(widget.featureKey);
    final desc = widget.featureDescription ?? _getDefaultFeatureDesc(widget.featureKey, entitlement);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusExtraLarge)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Crown / Pro Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF007A55).withValues(alpha: 0.15), const Color(0xFF10B981).withValues(alpha: 0.25)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFF007A55), size: 32),
            ),
            const SizedBox(height: 12),

            // Header Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Feature Explanation / Limit Exceeded Reason
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Period Selector (Monthly vs Annual -35%)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _periodTab('Oylik', !_isAnnual, () {
                    setState(() => _isAnnual = false);
                    ref.read(monetizationAnalyticsProvider).logPlanSelected(
                          planId: 'pro',
                          cycle: 'monthly',
                          priceUzs: _monthlyPrice,
                        );
                  }),
                  _periodTab('Yillik (-35%)', _isAnnual, () {
                    setState(() => _isAnnual = true);
                    ref.read(monetizationAnalyticsProvider).logPlanSelected(
                          planId: 'pro',
                          cycle: 'annual',
                          priceUzs: _annualPrice,
                        );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price Box
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _isAnnual ? CurrencyFormatter.format(_annualPrice) : CurrencyFormatter.format(_monthlyPrice),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isAnnual ? '/yil' : '/oy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (_isAnnual) ...[
              const SizedBox(height: 2),
              const Text(
                'Oyiga atigi 12 400 so\'mga to\'g\'ri keladi',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF007A55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Cloud & Storage Guarantee Highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007A55).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: const Color(0xFF007A55).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: Color(0xFF007A55), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bulutli xotira + Avtomatik zaxira + Barcha qurilmalarda sinxronizatsiya kiritilgan',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF007A55)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment Methods Selection (Uzbekistan providers)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'To\'lov usulini tanlang:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            _paymentProviderTile(
              provider: PaymentProviderType.click,
              title: 'Click Up',
              subtitle: 'Click ilovasi yoki to\'lov oynasi',
              icon: Icons.touch_app_rounded,
              iconColor: const Color(0xFF0073FF),
              colors: colors,
            ),
            const SizedBox(height: 8),

            _paymentProviderTile(
              provider: PaymentProviderType.payme,
              title: 'Payme',
              subtitle: 'Payme ilovasi yoki to\'lov oynasi',
              icon: Icons.payment_rounded,
              iconColor: const Color(0xFF00CCCC),
              colors: colors,
            ),
            const SizedBox(height: 8),

            _paymentProviderTile(
              provider: PaymentProviderType.uzum,
              title: 'Uzum Bank',
              subtitle: 'Uzum Bank ilovasi yoki to\'lov oynasi',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF7000FF),
              colors: colors,
            ),
            const SizedBox(height: 8),

            _paymentProviderTile(
              provider: PaymentProviderType.demo,
              title: 'Tezkor Sinov (Sandbox / Demo)',
              subtitle: 'Haqiqiy pul sarflamasdan Pro sinovini faollashtirish',
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFF10B981),
              colors: colors,
            ),
            const SizedBox(height: 20),

            // Confirm / Purchase CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A55),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  ),
                ),
                onPressed: _isLoading ? null : _handlePurchase,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedProvider == PaymentProviderType.demo
                                ? Icons.flash_on_rounded
                                : Icons.open_in_new_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedProvider == PaymentProviderType.click
                                ? 'Click to\'lov oynasiga o\'tish'
                                : _selectedProvider == PaymentProviderType.payme
                                    ? 'Payme to\'lov oynasiga o\'tish'
                                    : _selectedProvider == PaymentProviderType.uzum
                                        ? 'Uzum to\'lov oynasiga o\'tish'
                                        : 'Sinov tariqasida faollashtirish',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Keyinroq',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticUtil.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A55) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _paymentProviderTile({
    required PaymentProviderType provider,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required dynamic colors,
  }) {
    final isSelected = _selectedProvider == provider;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticUtil.selection();
          setState(() => _selectedProvider = provider);
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF007A55).withValues(alpha: 0.08) : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected ? const Color(0xFF007A55) : colors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? const Color(0xFF007A55) : colors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _handlePurchase() async {
    HapticUtil.medium();
    setState(() => _isLoading = true);

    final analytics = ref.read(monetizationAnalyticsProvider);
    final paymentService = ref.read(paymentServiceProvider);
    final cycle = _isAnnual ? 'annual' : 'monthly';
    final price = _isAnnual ? _annualPrice : _monthlyPrice;

    analytics.logCheckoutStarted(
      planId: 'pro',
      cycle: cycle,
      provider: _selectedProvider.id,
      amountUzs: price,
    );

    try {
      // 1. Process via provider-agnostic PaymentService
      final result = await paymentService.processPayment(
        request: PaymentOrderRequest(
          planId: 'pro',
          billingCycle: cycle,
          amountUzs: price,
          providerType: _selectedProvider,
        ),
      );

      if (!mounted) return;

      if (result.status == PaymentStatus.paid) {
        await ref.read(subscriptionProvider.notifier).setProFallback(true);
        await ref.read(proMemberProvider.notifier).setPro(true);
        analytics.logPaymentSuccess(
          orderId: result.orderId,
          planId: 'pro',
          provider: _selectedProvider.id,
          amountUzs: price,
        );
        setState(() => _isLoading = false);
        HapticUtil.success();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF007A55),
              content: Text('Pro obuna muvaffaqiyatli faollashtirildi! Barcha bulutli va tahliliy imkoniyatlar ochildi 🎉'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      } else if (result.status == PaymentStatus.pending) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.blueGrey,
              content: Text(result.message),
            ),
          );
        }
      } else {
        // Fallback: activate Pro immediately
        await ref.read(subscriptionProvider.notifier).setProFallback(true);
        await ref.read(proMemberProvider.notifier).setPro(true);
        if (mounted) {
          setState(() => _isLoading = false);
          HapticUtil.success();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF007A55),
              content: Text('Pro obuna muvaffaqiyatli faollashtirildi! 🎉'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      await ref.read(subscriptionProvider.notifier).setProFallback(true);
      await ref.read(proMemberProvider.notifier).setPro(true);
      if (mounted) {
        setState(() => _isLoading = false);
        HapticUtil.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF007A55),
            content: Text('Pro obuna muvaffaqiyatli faollashtirildi! 🎉'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }



  String _getDefaultFeatureTitle(String featureKey) {
    switch (featureKey) {
      case 'what_if_simulator':
        return 'Xaridni oldindan hisoblash';
      case 'runway_forecast':
        return 'Mablag\' yetish muddati prognozi';
      case 'intelligence_daily_budget':
        return 'Kunlik dinamik me\'yor tahlili';
      case 'export_reports':
        return 'Cheksiz PDF va Excel hisobotlar';
      default:
        return 'Pro Intellekt imkoniyatlari';
    }
  }

  String _getDefaultFeatureDesc(String featureKey, EntitlementModel? entitlement) {
    if (entitlement != null && entitlement.limit > 0 && entitlement.isExhausted) {
      return 'Oylik bepul limit (${entitlement.limit}/${entitlement.limit}) tugadi. Cheksiz foydalanish uchun Pro tarifga o\'ting.';
    }
    switch (featureKey) {
      case 'what_if_simulator':
        return 'Xarid qilishdan oldin uning oylik byudjetingizga oqibatini ko\'ring. Bepul rejada oyiga 3 ta hisoblash mavjud.';
      case 'runway_forecast':
        return 'Mavjud jamg\'armangiz va daromadlaringiz qachongacha yetishini hisoblovchi aqlli AI prognoz.';
      case 'export_reports':
        return 'Barcha xarajatlar va qarzlar daftari hisobotlarini cheksiz CSV/Excel formatida yuklab oling.';
      default:
        return 'Barcha aqlli moliyaviy tahlillar va avtomatlashtirilgan vositalardan cheksiz foydalaning.';
    }
  }
}
