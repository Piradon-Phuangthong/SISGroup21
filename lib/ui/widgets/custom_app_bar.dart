import 'package:flutter/material.dart';
import 'package:omada/main.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Omada',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle theme',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () async {
            final root = context.findAncestorWidgetOfExactType<OmadaRootApp>();
            if (root == null) return;
            await root.themeController.toggleLightDark();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
