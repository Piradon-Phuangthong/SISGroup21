import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String displayName;
  final Color colorText;
  const Avatar({super.key, required this.displayName, required this.colorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                      Color(0xFF93c5fd),
                      Color(0xFF4f46e5),
                      Color(0xFF1e40af),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width * 0.12,
                    MediaQuery.of(context).size.width * 0.12,
                    MediaQuery.of(context).size.width * 0.18,
                    MediaQuery.of(context).size.width * 0.18,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(0.2, -0.1),
                        colors: [
                          Color(0xFF7dd3fc),
                          Color(0xFF60a5fa),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 0.85],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorText,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
