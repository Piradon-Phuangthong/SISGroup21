import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';

class ExpandedOmadaHeader extends StatelessWidget {
  const ExpandedOmadaHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onDiscover,
    required this.onRequests,
    required this.onCreate,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final VoidCallback onDiscover;
  final VoidCallback onRequests;
  final VoidCallback onCreate;

  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // ↑ a touch more top padding to sit lower
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // extra spacer so title sits lower than the notch
              const SizedBox(height: 6),

              // Title → “Omadas” (not all caps)
              Text(
                'Omadas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 12),

              // Shorter search bar: center + max width cap
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FractionallySizedBox(
                    // 0.88 of available width on small screens
                    widthFactor: 0.88,
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => onSearchChanged(),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: Colors.white), // typing color
                      decoration: InputDecoration(
                        hintText: 'Search Omadas...',
                        hintStyle: const TextStyle(color: Colors.white70), // hint color
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                  ),
                ),
              ),

              const SizedBox(height: 18), // buttons sit a bit lower

              // Action row (Discover • Requests • Add)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _HeaderActionTile(
                    icon: Icons.travel_explore,
                    label: 'Discover',
                    keyId: 'discover',
                  ),
                  SizedBox(width: 12),
                  _HeaderActionTile(
                    icon: Icons.inbox_outlined,
                    label: 'Requests',
                    keyId: 'requests',
                  ),
                  SizedBox(width: 12),
                  _HeaderActionTile(
                    icon: Icons.add,
                    label: 'Add',
                    keyId: 'create',
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionTile extends StatelessWidget {
  const _HeaderActionTile({
    required this.icon,
    required this.label,
    required this.keyId,
  });

  final IconData icon;
  final String label;
  final String keyId;

  @override
  Widget build(BuildContext context) {
    VoidCallback? onTap;
    final parent =
        context.findAncestorWidgetOfExactType<ExpandedOmadaHeader>();
    if (parent != null) {
      if (keyId == 'discover') onTap = parent.onDiscover;
      if (keyId == 'requests') onTap = parent.onRequests;
      if (keyId == 'create') onTap = parent.onCreate;
    }

    final tile = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          tile,
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
