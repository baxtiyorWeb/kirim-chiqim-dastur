import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../providers/finance_providers.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _isAnnual = true;

  static const int _monthlyPrice = 19000;
  static const int _annualPrice = 149000; // ~12,416 UZS/mo (~35% discount)

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPro = ref.watch(proMemberProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ta\'rif rejalari',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.space12),

              // Title
              Text(
                'Hisob-kitob emas,\nMoliyaviy Qaror Tizimi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: AppDimensions.space8),

              // Subtitle
              Text(
                'Oddiy daftarga yozish o\'rniga, xarid qilishdan oldin oqibatini ko\'ring va pulingiz rejasiz tugashidan saqlaning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // Annual / Monthly Toggle Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodTab(
                      title: 'Oylik',
                      isSelected: !_isAnnual,
                      onTap: () {
                        HapticUtil.selection();
                        setState(() => _isAnnual = false);
                      },
                    ),
                    _buildPeriodTab(
                      title: 'Yillik (-35%)',
                      isSelected: _isAnnual,
                      onTap: () {
                        HapticUtil.selection();
                        setState(() => _isAnnual = true);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // Active Plan Status if Pro
              if (isPro) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sizda Pro obuna faol ✨',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Builder(builder: (context) {
                              final sub = ref.watch(subscriptionProvider);
                              final exp = sub.subscription.currentPeriodEnd;
                              if (exp != null) {
                                return Text(
                                  'Amal qilish muddati: ${exp.day}.${exp.month.toString().padLeft(2, '0')}.${exp.year}',
                                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                                );
                              }
                              return Text(
                                'Barcha aqlli tahlillar va hisob-kitoblar ochiq',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          HapticUtil.light();
                          await ref.read(subscriptionProvider.notifier).cancelSubscription();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pro obuna bekor qilindi (bepul reja faol)'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text('Bekor qilish', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),
              ],

              // PRO PLAN HERO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0F2B1D), const Color(0xFF13221C)]
                        : [const Color(0xFFE8F8F0), const Color(0xFFF0FDF4)],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                  border: Border.all(
                    color: const Color(0xFF007A55).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007A55).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    const Text(
                      'Pro imkoniyatlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF007A55),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space12),

                    // Price display
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _isAnnual
                              ? CurrencyFormatter.format(_annualPrice)
                              : CurrencyFormatter.format(_monthlyPrice),
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
                            fontWeight: FontWeight.w500,
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

                    const SizedBox(height: AppDimensions.space12),
                    const Divider(height: 1),
                    const SizedBox(height: AppDimensions.space12),

                    // Features List
                    _buildFeatureItem(
                      icon: Icons.shield_rounded,
                      title: 'Kunlik xarajat dinamik me\'yori',
                      subtitle: 'Har kuni xavfsiz sarflashingiz mumkin bo\'lgan aniq chegara',
                      colors: colors,
                    ),
                    _buildFeatureItem(
                      icon: Icons.calculate_outlined,
                      title: 'Xaridni oldindan hisoblash',
                      subtitle: 'Qaror qabul qilishdan oldin oylik byudjetingizga ta\'sirini ko\'ring',
                      colors: colors,
                    ),
                    _buildFeatureItem(
                      icon: Icons.hourglass_top_rounded,
                      title: 'Mablag\' yetish muddati prognozi',
                      subtitle: 'Mavjud pulingiz qachongacha yetishini hisoblash',
                      colors: colors,
                    ),
                    _buildFeatureItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Aqlli byudjet va qarz nazorati',
                      subtitle: 'Ortiqcha xarajatlarni kamaytirish bo\'yicha amaliy tavsiyalar',
                      colors: colors,
                    ),
                    _buildFeatureItem(
                      icon: Icons.file_download_outlined,
                      title: 'Cheksiz PDF va Excel hisobotlar',
                      subtitle: 'Hisobotlarni qulay formatda yuklab olish',
                      colors: colors,
                    ),
                    _buildFeatureItem(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Avtomatik bulutli zaxira',
                      subtitle: 'Telefoningiz o\'zgarganda ham ma\'lumotlaringiz xavfsiz',
                      colors: colors,
                    ),

                    const SizedBox(height: AppDimensions.space20),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A55),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                          ),
                        ),
                        onPressed: isPro
                            ? null
                            : () async {
                                HapticUtil.medium();
                                await showPaywallSheet(context, featureKey: 'pricing_screen');
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isPro ? Icons.verified_rounded : Icons.lock_open_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isPro
                                  ? 'Sizda Pro Obuna Faol ✨'
                                  : (_isAnnual
                                      ? 'Yillik Pro Rejaga Ulanish (Click / Payme)'
                                      : 'Oylik Pro Rejaga Ulanish (Click / Payme)'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Istalgan vaqtda bekor qilish mumkin • Yashirin to\'lov yo\'q',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // FREE PLAN CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16191F) : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Oddiy Reja',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '0 so\'m',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faqat shu qurilmada mustaqil ishlaydigan oflayn moliyaviy hisob-kitob daftari.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSimpleFeature('To\'liq oflayn ishlash (internetsiz)', colors, true),
                    _buildSimpleFeature('Cheksiz daromad va xarajat kiritish', colors, true),
                    _buildSimpleFeature('Mahalliy xotira (faqat shu telefonda)', colors, true),
                    _buildSimpleFeature('Oddiy qarzlar ro\'yxati va toifalar', colors, true),
                    _buildSimpleFeature('Bulutli zaxira va sinxronizatsiya', colors, false),
                    _buildSimpleFeature('Boshqa qurilmalarda bir xil hisob', colors, false),
                    _buildSimpleFeature('Xaridni oldindan AI simulyatsiya qilish', colors, false),
                    _buildSimpleFeature('Mablag\' yetish muddati (Runway) prognozi', colors, false),
                    _buildSimpleFeature('Cheksiz PDF va Excel hisobot eksporti', colors, false),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // 5-SECOND COMPARISON MATRIX TABLE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16191F) : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tezkor taqqoslash (5 soniyada)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Siz uchun eng qulay tarifni tanlang:',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _buildComparisonRow('Imkoniyat', 'Oddiy', 'Pro ✨', isHeader: true, colors: colors),
                    const Divider(height: 16),
                    _buildComparisonRow('Oflayn xotira (internetsiz)', 'Mavjud', 'Mavjud', colors: colors),
                    _buildComparisonRow('Bulutli zaxira va tiklash', 'Yo\'q', 'Avtomatik', colors: colors),
                    _buildComparisonRow('Ko\'p qurilmada sinxronizatsiya', 'Yo\'q', 'Ha', colors: colors),
                    _buildComparisonRow('Telefon yo\'qolganda ma\'lumot', 'Yo\'qoladi', 'Saqlanadi', colors: colors),
                    _buildComparisonRow('Xaridni simulyatsiya qilish', '3 ta/oy', 'Cheksiz', colors: colors),
                    _buildComparisonRow('Mablag\' yetish prognozi', 'Yo\'q', 'To\'liq', colors: colors),
                    _buildComparisonRow('PDF / Excel eksport', 'Yo\'q', 'Cheksiz', colors: colors),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              // ROI / Value Guarantee Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A55).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF007A55),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Moliyaviy kafolat nima?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Agar ilova sizni bittagina 200,000 so\'mlik asossiz xarid yoki qarz foizidan asrab qolsa — u o\'zining 1 yillik narxini to\'liq oqlaydi.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A55) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeTokens colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF007A55).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF007A55), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFeature(String text, AppThemeTokens colors, bool included) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            size: 16,
            color: included ? const Color(0xFF10B981) : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: included ? FontWeight.w500 : FontWeight.w400,
                color: included ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.6),
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String freeValue,
    String proValue, {
    bool isHeader = false,
    required AppThemeTokens colors,
  }) {
    final style = TextStyle(
      fontSize: isHeader ? 12.5 : 12,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
      color: isHeader ? colors.textPrimary : colors.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              proValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isHeader ? 12.5 : 12,
                fontWeight: FontWeight.w700,
                color: isHeader ? const Color(0xFF007A55) : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
