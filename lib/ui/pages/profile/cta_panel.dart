import 'package:flutter/material.dart';

class CtaPanel extends StatelessWidget {
  final String centerValue;
  final VoidCallback onAdd;
  final VoidCallback onShare;
  final VoidCallback onQuickCall;
  const CtaPanel({
    super.key,
    required this.centerValue,
    required this.onAdd,
    required this.onShare,
    required this.onQuickCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e40af).withOpacity(0.28),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
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
          ),
          _CallButton(onTap: onQuickCall),
          _CtaItem(
            icon: Icons.share,
            title: 'Share',
            value: centerValue,
            onTap: onShare,
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
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
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

class _CallButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CallButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(0, -0.4),
            radius: 0.8,
            colors: [Color(0xFF93c5fd), Color(0xFF60a5fa), Color(0xFF3b82f6)],
            stops: [0.0, 0.7, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 6),
        ),
        child: const Icon(Icons.bolt, size: 34, color: Colors.black87),
      ),
    );
  }
}
