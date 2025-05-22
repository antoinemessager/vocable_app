import 'package:flutter/material.dart';

class StarAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final int currentCount;
  final GlobalKey masteredKey;

  const StarAnimation({
    super.key,
    required this.onComplete,
    required this.currentCount,
    required this.masteredKey,
  });

  @override
  State<StarAnimation> createState() => _StarAnimationState();
}

class _StarAnimationState extends State<StarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Offset? _startPosition;
  Offset? _endPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 2.0, end: 2.5), weight: 0.5),
      TweenSequenceItem(
          tween: Tween<double>(begin: 2.5, end: 1.0), weight: 0.5),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          widget.masteredKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        setState(() {
          _startPosition = position + Offset(size.width / 2, size.height / 2);
          _endPosition = position + Offset(size.width / 2, 14);
        });
        _controller.forward().then((_) {
          widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_startPosition == null || _endPosition == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentPosition = Offset(
          _startPosition!.dx +
              (_endPosition!.dx - _startPosition!.dx) *
                  _positionAnimation.value,
          _startPosition!.dy +
              (_endPosition!.dy - _startPosition!.dy) *
                  _positionAnimation.value,
        );

        return Positioned(
          left: currentPosition.dx - 24, // Half of the star size
          top: currentPosition.dy - 24, // Half of the star size
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}
