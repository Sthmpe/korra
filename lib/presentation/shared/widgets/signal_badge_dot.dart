// lib/presentation/shared/widgets/signal_badge_dot.dart

import 'package:flutter/material.dart';

/// A red notification dot that "broadcasts": expanding, fading rings ripple
/// out of it like a signal beacon. Used on the Stores nav tab to nudge
/// customers back to an unfinished cart.
class SignalBadgeDot extends StatefulWidget {
  /// Diameter of the core dot in logical pixels — pass an already-scaled
  /// value (e.g. `8.w`); no scaling is applied internally.
  final double size;

  const SignalBadgeDot({super.key, this.size = 8});

  @override
  State<SignalBadgeDot> createState() => _SignalBadgeDotState();
}

class _SignalBadgeDotState extends State<SignalBadgeDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = widget.size;
    final field = dot * 3; // room for the ripples to expand into

    return SizedBox(
      width: field,
      height: field,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _ripple(_controller.value, dot, field),
              _ripple((_controller.value + 0.5) % 1.0, dot, field),
              // The core red dot
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// One expanding ring at progress [t] (0 → 1): grows from the dot outwards
  /// while fading, like a signal wave.
  Widget _ripple(double t, double dot, double field) {
    final size = dot + (field - dot) * t;
    final opacity = (1.0 - t) * 0.55;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withValues(alpha: opacity),
          width: 1.6,
        ),
      ),
    );
  }
}