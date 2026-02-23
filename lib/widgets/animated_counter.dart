import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    // Correction: Utilisation de curves standards disponibles dans Flutter
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // Remplacé easeOutQuartic par easeOutCubic
    );
    _controller.forward();
    _animation.addListener(() {
      setState(() {
        _displayValue = (_animation.value * widget.value).round();
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayValue.toString(), style: widget.style);
  }
}
