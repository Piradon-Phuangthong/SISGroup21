import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';

class AppTagChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppTagChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Theme.of(context).colorScheme.secondary;
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmadaTokens.space8,
        vertical: OmadaTokens.space4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: OmadaTokens.radius12),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: OmadaTokens.fontSm,
          fontWeight: OmadaTokens.weightMedium,
          height: 1.1,
        ),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
