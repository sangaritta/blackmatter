import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: widget.color ?? Colors.white,
      end: (widget.color ?? const Color.fromARGB(255, 218, 179, 255)).withValues(
        red: (widget.color ?? const Color.fromARGB(255, 255, 0, 106)).r,
        green: (widget.color ?? const Color.fromARGB(255, 0, 255, 106)).g,
        blue: (widget.color ?? const Color.fromARGB(255, 68, 0, 255)).b,
        alpha: 0.3,
      ),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return LoadingAnimationWidget.stretchedDots(
            color: _colorAnimation.value ?? Colors.white,
            size: widget.size,
          );
        },
      ),
    );
  }
}
