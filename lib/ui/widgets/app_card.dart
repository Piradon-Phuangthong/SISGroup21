import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: OmadaTokens.radius12,
        boxShadow: OmadaTokens.shadowSm,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(OmadaTokens.space16),
        child: child,
      ),
    );
  }
}
