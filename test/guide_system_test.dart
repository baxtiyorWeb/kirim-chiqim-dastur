import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thego_getters/core/guide/guide.dart';

void main() {
  group('Guide Models & State Tests', () {
    test('GuideStep creates properly with default and custom values', () {
      const step = GuideStep(
        id: 'step_1',
        targetId: 'target_balance',
        title: 'Balans',
        description: 'Umumiy balans ko‘rsatkichi',
        placement: GuidePlacement.bottom,
        shape: GuideTargetShape.rrect,
        borderRadius: 24.0,
      );

      expect(step.id, 'step_1');
      expect(step.targetId, 'target_balance');
      expect(step.title, 'Balans');
      expect(step.placement, GuidePlacement.bottom);
      expect(step.shape, GuideTargetShape.rrect);
      expect(step.borderRadius, 24.0);
    });

    test('GuideState initial and copyWith transitions correctly', () {
      const initial = GuideState();
      expect(initial.isActive, isFalse);
      expect(initial.status, GuideStatus.idle);

      final started = initial.copyWith(
        status: GuideStatus.showing,
        tour: AppTours.firstLaunchTour,
        stepIndex: 0,
        targetRect: const Rect.fromLTWH(20, 100, 300, 80),
      );

      expect(started.isActive, isTrue);
      expect(started.status, GuideStatus.showing);
      expect(started.currentStep?.id, 'welcome');
      expect(started.totalSteps, AppTours.firstLaunchTour.steps.length);
      expect(started.progressRatio, closeTo(1 / AppTours.firstLaunchTour.steps.length, 0.01));
    });

    test('AppTours definitions have valid ids and steps', () {
      expect(AppTours.firstLaunchTour.id, AppTours.firstLaunchTourId);
      expect(AppTours.firstLaunchTour.steps.isNotEmpty, isTrue);

      expect(AppTours.budgetContextualTour.id, AppTours.budgetTourId);
      expect(AppTours.budgetContextualTour.steps.isNotEmpty, isTrue);

      expect(AppTours.debtsContextualTour.id, AppTours.debtsTourId);
      expect(AppTours.debtsContextualTour.steps.isNotEmpty, isTrue);
    });
  });

  group('GuideRegistry Tests', () {
    testWidgets('GuideTarget registers and unregisters cleanly with lifecycle', (tester) async {
      final registry = GuideRegistry.instance;
      expect(registry.hasTarget('test_target'), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideTarget(
              id: 'test_target',
              child: Container(
                key: const ValueKey('inner_container'),
                width: 100,
                height: 50,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(registry.hasTarget('test_target'), isTrue);

      final rect = registry.getTargetRect('test_target');
      expect(rect, isNotNull);
      expect(rect!.width, 100);
      expect(rect.height, 50);

      // Rebuilding without the widget unregisters the target
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(registry.hasTarget('test_target'), isFalse);
      expect(registry.getTargetRect('test_target'), isNull);
    });
  });
}
