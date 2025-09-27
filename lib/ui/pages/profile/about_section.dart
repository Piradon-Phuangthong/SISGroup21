import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  final String title;
  final Color textColor;
  const AboutSection({super.key, required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor.withOpacity(0.8), height: 1.45),
      ),
    );
  }
}
