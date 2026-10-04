import 'dart:async';
import 'package:flutter/material.dart';

class GuideTargetEntry {
  final String id;
  final GlobalKey key;
  final BuildContext context;

  const GuideTargetEntry({
    required this.id,
    required this.key,
    required this.context,
  });
}

/// Central registry managing active highlight targets.
/// Ensures safe registration and disposal of RenderBox references
/// without leaking memory or retaining dead widget contexts.
class GuideRegistry {
  GuideRegistry._();
  static final GuideRegistry instance = GuideRegistry._();

  final Map<String, GuideTargetEntry> _targets = {};
  final List<void Function(String targetId)> _registrationListeners = [];

  void register({
    required String id,
    required GlobalKey key,
    required BuildContext context,
  }) {
    _targets[id] = GuideTargetEntry(id: id, key: key, context: context);
    for (final listener in List.of(_registrationListeners)) {
      listener(id);
    }
  }

  void unregister(String id) {
    _targets.remove(id);
  }

  bool hasTarget(String id) => _targets.containsKey(id);

  GuideTargetEntry? getEntry(String id) => _targets[id];

  BuildContext? getContext(String id) {
    final entry = _targets[id];
    if (entry != null && entry.context.mounted) {
      return entry.context;
    }
    return null;
  }

  /// Calculates the global screen Rect geometry for the given target.
  /// Returns null if target is not mounted or not yet laid out.
  Rect? getTargetRect(String id) {
    final entry = _targets[id];
    if (entry == null) return null;

    final context = entry.key.currentContext ?? (entry.context.mounted ? entry.context : null);
    if (context == null || !context.mounted) return null;

    try {
      final renderBox = context.findRenderObject();
      if (renderBox is! RenderBox || !renderBox.hasSize || !renderBox.attached) {
        return null;
      }

      final translation = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      if (size.width <= 0 || size.height <= 0) return null;

      return Rect.fromLTWH(
        translation.dx,
        translation.dy,
        size.width,
        size.height,
      );
    } catch (_) {
      return null;
    }
  }

  /// Waits asynchronously for a target to be registered and laid out, with a timeout.
  Future<Rect?> waitForTargetGeometry(
    String id, {
    Duration timeout = const Duration(milliseconds: 2000),
  }) async {
    // 1. Check if already ready
    final immediateRect = getTargetRect(id);
    if (immediateRect != null && immediateRect.width > 0 && immediateRect.height > 0) {
      return immediateRect;
    }

    final completer = Completer<Rect?>();
    Timer? periodicTimer;
    final stopwatch = Stopwatch()..start();

    void check() {
      if (completer.isCompleted) return;
      final rect = getTargetRect(id);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        periodicTimer?.cancel();
        completer.complete(rect);
      } else if (stopwatch.elapsed >= timeout) {
        periodicTimer?.cancel();
        completer.complete(rect);
      }
    }

    // Check on next post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) => check());

    // Also poll every 60ms up to timeout (max ~33 checks, minimal cost, guarantees capture after route/frame transitions)
    periodicTimer = Timer.periodic(const Duration(milliseconds: 60), (_) => check());

    return completer.future;
  }

  void clearAll() {
    _targets.clear();
    _registrationListeners.clear();
  }
}
