import 'package:flutter/material.dart';

class CtaPanel extends StatelessWidget {
  final String centerValue;
  final VoidCallback onAdd;
  final VoidCallback onShare;
  final VoidCallback onQuickCall;
  final Gradient? backgroundGradient;
  final Gradient? callButtonGradient;
  const CtaPanel({
    super.key,
    required this.centerValue,
    required this.onAdd,
    required this.onShare,
    required this.onQuickCall,
    this.backgroundGradient,
    this.callButtonGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundGradient == null
            ? const Color(0xFF1e40af).withValues(alpha: 0.28)
            : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CtaItem(
            icon: Icons.add,
            title: 'Add',
            value: 'Channel',
            onTap: onAdd,
          ),
          // Center: Share (slightly larger)
          _CenterActionButton(
            icon: Icons.share,
            onTap: onShare,
            gradient: callButtonGradient,
            size: 82,
            caption: centerValue,
          ),
          // Right: Quick Call moved from center
          _CtaItem(
            icon: Icons.call,
            title: 'Call',
            value: 'Quick',
            onTap: onQuickCall,
          ),
        ],
      ),
    );
  }
}

class _CtaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _CtaItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                // Make the button background less transparent for better visibility
                color: Colors.white.withValues(alpha: 0.30),
                // Add faint white border for extra contrast on deep gradient areas
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                // Slightly increase label opacity to improve legibility
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _CallButton removed after swapping: center action is now Share.

// Center prominent action button with optional caption (used for Share)
class _CenterActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double size;
  final String? caption;

  const _CenterActionButton({
    required this.icon,
    this.onTap,
    this.gradient,
    this.size = 82,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient ??
                  const RadialGradient(
                    center: Alignment(0, -0.4),
                    radius: 0.9,
                    colors: [Color(0xFF93c5fd), Color(0xFF60a5fa), Color(0xFF3b82f6)],
                    stops: [0.0, 0.7, 1.0],
                  ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(115, 38, 55, 112),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 6),
            ),
            child: Icon(icon, size: 34, color: const Color.fromARGB(221, 241, 240, 240)),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
