import 'package:flutter/material.dart';

/// ChatGPT-EXACT animation utilities
/// All durations and curves match ChatGPT precisely
class AppAnimations {
  AppAnimations._();

  // ═══════════════════════════════════════════════════════════════
  //                    DURATION CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  static const Duration fastest = Duration(milliseconds: 100);    // Button press
  static const Duration fast = Duration(milliseconds: 150);       // Hover effects
  static const Duration normal = Duration(milliseconds: 200);     // Message appear
  static const Duration medium = Duration(milliseconds: 250);     // Modal appear
  static const Duration slow = Duration(milliseconds: 300);       // Sidebar slide
  static const Duration slower = Duration(milliseconds: 400);     // Ripple effect

  // Typing indicator
  static const Duration typingCycle = Duration(milliseconds: 1200);
  static const Duration typingDotDelay = Duration(milliseconds: 150);

  // Voice waveform
  static const Duration waveformPulse = Duration(milliseconds: 150);

  // ═══════════════════════════════════════════════════════════════
  //                    CURVE CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  static const Curve standard = Curves.easeOut;
  static const Curve emphasized = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;

  // ═══════════════════════════════════════════════════════════════
  //                    SCALE CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  static const double buttonPressScale = 0.96;
  static const double buttonPressOpacity = 0.9;
  static const double modalStartScale = 0.95;
  static const double cardHoverScale = 1.02;

  // ═══════════════════════════════════════════════════════════════
  //                    SLIDE OFFSETS
  // ═══════════════════════════════════════════════════════════════

  static const Offset sidebarSlideStart = Offset(-1, 0);
  static const Offset sidebarSlideEnd = Offset.zero;
  static const Offset messageSlideStart = Offset(0, 0.1);
  static const Offset messageSlideEnd = Offset.zero;
  static const Offset modalSlideStart = Offset(0, 0.05);
  static const Offset modalSlideEnd = Offset.zero;

  // ═══════════════════════════════════════════════════════════════
  //                    ANIMATION BUILDERS
  // ═══════════════════════════════════════════════════════════════

  /// Button press animation (scale + opacity)
  static Widget buttonPress({
    required Widget child,
    required bool isPressed,
  }) {
    return AnimatedScale(
      scale: isPressed ? buttonPressScale : 1.0,
      duration: fastest,
      curve: standard,
      child: AnimatedOpacity(
        opacity: isPressed ? buttonPressOpacity : 1.0,
        duration: fastest,
        child: child,
      ),
    );
  }

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    required bool show,
    Duration duration = normal,
  }) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: duration,
      curve: standard,
      child: child,
    );
  }

  /// Slide up animation
  static Widget slideUp({
    required Widget child,
    required bool show,
    Duration duration = medium,
  }) {
    return AnimatedSlide(
      offset: show ? Offset.zero : const Offset(0, 0.1),
      duration: duration,
      curve: standard,
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: duration,
        curve: standard,
        child: child,
      ),
    );
  }
}

/// Animated button with press feedback
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? AppAnimations.buttonPressScale : 1.0,
        duration: AppAnimations.fastest,
        curve: AppAnimations.standard,
        child: AnimatedOpacity(
          opacity: _isPressed ? AppAnimations.buttonPressOpacity : 1.0,
          duration: AppAnimations.fastest,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Typing indicator with bouncing dots
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.typingCycle,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Staggered animation for each dot
              final delay = index * 0.15;
              final animation = (_controller.value - delay) % 1.0;
              final bounce = (animation < 0.5)
                  ? animation * 2
                  : (1 - animation) * 2;

              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 3 : 0),
                child: Transform.translate(
                  offset: Offset(0, -bounce * 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8E8EA0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Ripple effect wrapper
class RippleWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const RippleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: child,
      ),
    );
  }
}
