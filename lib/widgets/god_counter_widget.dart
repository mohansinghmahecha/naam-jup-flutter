import 'package:flutter/material.dart';
import '../models/god.dart';

class GodCounterWidget extends StatefulWidget {
  final God god;
  final double progress;
  final bool isResetting;
  final VoidCallback onTap;

  const GodCounterWidget({
    super.key,
    required this.god,
    required this.progress,
    required this.isResetting,
    required this.onTap,
  });

  @override
  State<GodCounterWidget> createState() => _GodCounterWidgetState();
}

class _GodCounterWidgetState extends State<GodCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.god.sessionCount % 108;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque, // ✅ makes empty areas clickable too
      child: Container(
        width: 320, // ✅ bigger rectangular tap area
        height: 320,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 🌞 Outer 360° Aura Ring (Smooth & Spiritual)
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: 0,
                      endAngle: 6.28,
                      colors: [
                        Colors.yellow.withOpacity(0.2),
                        Colors.orange.withOpacity(0.6),
                        Colors.yellow.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),

                // 🟡 Inner Divine Sun Circle
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFF5722)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 35,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // ✨ Top → Bottom Light Movement
                Transform.translate(
                  offset: Offset(0, (-18 + (_controller.value * 36))),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.yellow.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ❤️ Count + Label
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'जप',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
