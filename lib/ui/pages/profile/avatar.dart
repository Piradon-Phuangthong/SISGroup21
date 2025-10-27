import 'package:flutter/material.dart';

class Avatar extends StatefulWidget {
  final String displayName;
  final Color colorText;
  const Avatar({super.key, required this.displayName, required this.colorText});

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _scale = Tween<double>(begin: 0.98, end: 1.04).animate(curved);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mq = context.mounted ? MediaQuery.maybeOf(context) : null;
      final disable = mq?.disableAnimations ?? false;
      if (!disable && mounted) {
        _controller.repeat(reverse: true);
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
    return Column(
      children: [
        ScaleTransition(
          scale: _scale,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.32,
            height: MediaQuery.of(context).size.width * 0.32,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.3, -0.3),
                      radius: 0.8,
                      colors: [
                        Color(0xFFB97EE5), // Light lavender
                        Color(0xFF5E2CCF), // Deep Purple (base)
                        Color(0xFF4A22A8), // Darker shade
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                // Inner glow removed to avoid a central dot; outer gradient provides the full look
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.colorText,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
