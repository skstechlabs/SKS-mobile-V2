import 'package:flutter/material.dart';

class SKSLoader extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  
  const SKSLoader({
    Key? key,
    this.size = 60,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<SKSLoader> createState() => _SKSLoaderState();
}

class _SKSLoaderState extends State<SKSLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: widget.backgroundColor != null
          ? BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
            )
          : null,
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Image.asset(
                'assets/images/SKS_Logo.png',
                width: widget.size * 0.7,
                height: widget.size * 0.7,
                fit: BoxFit.contain,
                // Performance optimization
                cacheWidth: (widget.size * 0.7 * MediaQuery.of(context).devicePixelRatio).toInt(),
                cacheHeight: (widget.size * 0.7 * MediaQuery.of(context).devicePixelRatio).toInt(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Simple static loader without animation for better performance
class SKSLoaderStatic extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  
  const SKSLoaderStatic({
    Key? key,
    this.size = 60,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            )
          : null,
      child: Center(
        child: Image.asset(
          'assets/images/SKS_Logo.png',
          width: size * 0.7,
          height: size * 0.7,
          fit: BoxFit.contain,
          // Performance optimization
          cacheWidth: (size * 0.7 * MediaQuery.of(context).devicePixelRatio).toInt(),
          cacheHeight: (size * 0.7 * MediaQuery.of(context).devicePixelRatio).toInt(),
        ),
      ),
    );
  }
}
