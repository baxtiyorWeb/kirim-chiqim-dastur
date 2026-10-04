import 'package:flutter/material.dart';
import '../models/guide_step.dart';
import '../models/guide_tour.dart';

/// Predefined guided tours for the application.
class AppTours {
  AppTours._();

  static const String firstLaunchTourId = 'first_launch_tour';
  static const String budgetTourId = 'budget_contextual_tour';
  static const String debtsTourId = 'debts_contextual_tour';

  /// Level 1 — First Launch Tour (5-8 essential polished steps)
  static final GuideTour firstLaunchTour = GuideTour(
    id: firstLaunchTourId,
    title: 'Ilova bilan tanishuv',
    steps: [
      // 0. Welcome modal
      const GuideStep(
        id: 'welcome',
        title: '👋 Xush kelibsiz!',
        description:
            'Moliyangizni boshqarish, xarajatlar va oylik smetani aniq nazorat qilishni bir necha qadamda o‘rganamiz.',
        placement: GuidePlacement.center,
        nextButtonText: 'Boshlash',
      ),

      // 1. Dashboard Balance
      const GuideStep(
        id: 'balance',
        targetId: 'dashboard_balance',
        route: '/dashboard',
        title: 'Joriy umumiy balans',
        description:
            'Hozirgi mavjud mablag‘ingiz shu yerda aks etadi. Boshlang‘ich kiritilgan mablag‘ va barcha xarajatlar hisobga olinadi.',
        borderRadius: 24.0,
        placement: GuidePlacement.bottom,
      ),

      // 2. Dashboard Month Expense
      const GuideStep(
        id: 'month_expense',
        targetId: 'dashboard_month_expense',
        route: '/dashboard',
        title: 'Bu oy xarajatlari',
        description:
            'Joriy oy davomida amalga oshirilgan barcha chiqimlaringiz yig‘indisi shu yerda umumlashtiriladi.',
        borderRadius: 20.0,
        placement: GuidePlacement.bottom,
      ),

      // 3. Dashboard Smeta Remainder
      const GuideStep(
        id: 'smeta_remainder',
        targetId: 'dashboard_smeta_qoldiq',
        route: '/dashboard',
        title: 'Smeta qoldig‘i',
        description:
            'Rejalashtirilgan oylik byudjetingizdan qancha limit mablag‘i qolganini shu yerda ko‘rishingiz mumkin.',
        borderRadius: 20.0,
        placement: GuidePlacement.bottom,
      ),

      // 4. Center Add Button
      const GuideStep(
        id: 'add_button',
        targetId: 'bottom_nav_add',
        route: '/dashboard',
        shape: GuideTargetShape.circle,
        targetPadding: EdgeInsets.all(8.0),
        title: 'Tezkor qo‘shish',
        description:
            'Yangi xarajat yoki daromadni birgina tegish bilan tezkorlik bilan kiritish uchun ushbu tugmadan foydalanasiz.',
        placement: GuidePlacement.top,
      ),

      // 5. Transactions Screen
      const GuideStep(
        id: 'transactions',
        targetId: 'transactions_list',
        route: '/transactions',
        title: 'Tranzaksiyalar tarixi',
        description:
            'Barcha kirim va chiqimlar to‘liq tarixi, qidiruv va toifalar filtri shu bo‘limda joylashgan.',
        borderRadius: 20.0,
        placement: GuidePlacement.bottom,
      ),

      // 6. Budget Screen
      const GuideStep(
        id: 'budget',
        targetId: 'budget_overview_card',
        route: '/budget',
        title: 'Oylik smeta (Budjet)',
        description:
            'Oy davomida qancha sarflashni rejalashtiring, limitlarni belgilang va ortiqcha xarajatlarning oldini oling.',
        borderRadius: 24.0,
        placement: GuidePlacement.bottom,
      ),

      // 7. Debts Screen
      const GuideStep(
        id: 'debts',
        targetId: 'debts_summary_overview',
        route: '/debts',
        title: 'Qarzlar daftari',
        description:
            'Kimdan pul olganingiz yoki kimga qarz berganingizni, to‘lov muddatlari bilan shu yerda nazorat qiling.',
        borderRadius: 24.0,
        placement: GuidePlacement.bottom,
      ),

      // 8. Completion Modal
      const GuideStep(
        id: 'completed',
        route: '/dashboard',
        title: '🎉 Hammasi tayyor!',
        description:
            'Siz ilovaning barcha asosiy imkoniyatlari bilan tanishdingiz. Endi moliyangizni to‘liq nazorat qilishni boshlang!',
        placement: GuidePlacement.center,
        nextButtonText: 'Ilovaga o‘tish',
      ),
    ],
  );

  /// Level 2 — Contextual Budget Tour
  static final GuideTour budgetContextualTour = GuideTour(
    id: budgetTourId,
    title: 'Smeta bilan tanishuv',
    steps: [
      const GuideStep(
        id: 'budget_overview',
        targetId: 'budget_overview_card',
        title: 'Oylik smeta ko‘rsatkichi',
        description:
            'Bu oy uchun belgilangan umumiy limit, sarflangan summa va qolgan limit miqdorini aniq ko‘rsatadi.',
        borderRadius: 24.0,
        placement: GuidePlacement.bottom,
      ),
      const GuideStep(
        id: 'budget_categories',
        targetId: 'budget_categories_list',
        title: 'Toifalar limiti',
        description:
            'Ovqatlanish, transport va boshqa sohalar bo‘yicha alohida limitlar o‘rnatib, xarajatlaringizni me’yorida ushlang.',
        borderRadius: 20.0,
        placement: GuidePlacement.top,
      ),
    ],
  );

  /// Level 2 — Contextual Debts Tour
  static final GuideTour debtsContextualTour = GuideTour(
    id: debtsTourId,
    title: 'Qarzlar daftari bilan tanishuv',
    steps: [
      const GuideStep(
        id: 'debts_overview',
        targetId: 'debts_summary_overview',
        title: 'Qarzlar umumiy ko‘rsatkichi',
        description:
            'Olingan qarzlar (siz to‘lashingiz kerak bo‘lgan) va berilgan qarzlar (sizga qaytarilishi kerak bo‘lgan) yig‘indisi.',
        borderRadius: 24.0,
        placement: GuidePlacement.bottom,
      ),
    ],
  );
}
