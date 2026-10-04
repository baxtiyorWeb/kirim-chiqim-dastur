import 'package:flutter/material.dart';
import '../services/guide_registry.dart';

/// Lightweight wrapper widget that registers a child with [GuideRegistry].
/// Automatically tracks mount, layout, and disposal lifecycles.
class GuideTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const GuideTarget({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  State<GuideTarget> createState() => _GuideTargetState();
}

class _GuideTargetState extends State<GuideTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant GuideTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      GuideRegistry.instance.unregister(oldWidget.id);
      _register();
    }
  }

  void _register() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GuideRegistry.instance.register(
          id: widget.id,
          key: _key,
          context: context,
        );
      }
    });
  }

  @override
  void dispose() {
    GuideRegistry.instance.unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
