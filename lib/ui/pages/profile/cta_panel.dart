import 'package:flutter/material.dart';

class CtaPanel extends StatelessWidget {
  final String centerValue;
  final VoidCallback onAdd;
  final VoidCallback onShare;
  final VoidCallback onQuickCall;
  final Gradient? backgroundGradient;
  final Gradient? callButtonGradient;
  final Color? backgroundColor;
  const CtaPanel({
    super.key,
    required this.centerValue,
    required this.onAdd,
    required this.onShare,
    required this.onQuickCall,
    this.backgroundGradient,
    this.callButtonGradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color panelColor = backgroundGradient == null
        ? (backgroundColor ?? const Color(0xFF1e40af).withValues(alpha: 0.28))
        : Colors.transparent;
    final bool isLightPanel = backgroundGradient == null &&
        (backgroundColor?.computeLuminance() ?? 0) > 0.75;
    final Color primaryTextOnPanel = isLightPanel
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    final Color secondaryTextOnPanel = isLightPanel
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.95);
    final Color circleFill = isLightPanel
        ? Colors.black.withOpacity(0.04)
        : Colors.white.withValues(alpha: 0.30);
    final Color circleBorder = isLightPanel
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withValues(alpha: 0.8);
  final Color sideIconColor = isLightPanel
    ? Theme.of(context).colorScheme.onSurface
    : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundGradient == null ? panelColor : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(96, 15, 85, 117),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
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
            titleColor: secondaryTextOnPanel,
            valueColor: primaryTextOnPanel,
            circleFill: circleFill,
            circleBorder: circleBorder,
            iconColor: sideIconColor,
          ),
          // Center: Share (slightly larger)
          _CenterActionButton(
            icon: Icons.share,
            onTap: onShare,
            gradient: callButtonGradient,
            size: 82,
            caption: centerValue,
            captionColor: primaryTextOnPanel,
          ),
          // Right: Quick Call moved from center
          _CtaItem(
            icon: Icons.call,
            title: 'Call',
            value: 'Quick',
            onTap: onQuickCall,
            titleColor: secondaryTextOnPanel,
            valueColor: primaryTextOnPanel,
            circleFill: circleFill,
            circleBorder: circleBorder,
            iconColor: sideIconColor,
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
  final Color? titleColor;
  final Color? valueColor;
  final Color? circleFill;
  final Color? circleBorder;
  final Color? iconColor;
  const _CtaItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.titleColor,
    this.valueColor,
    this.circleFill,
    this.circleBorder,
    this.iconColor,
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
                // Button background and border adapt to panel brightness
                color: circleFill ?? Colors.white.withValues(alpha: 0.30),
                border: Border.all(
                  color: circleBorder ?? Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                // Label color adapts to panel brightness
                color: titleColor ?? Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
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
  final Color? captionColor;

  const _CenterActionButton({
    required this.icon,
    this.onTap,
    this.gradient,
    this.size = 82,
    this.caption,
    this.captionColor,
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
            style: TextStyle(
              color: captionColor ?? Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
