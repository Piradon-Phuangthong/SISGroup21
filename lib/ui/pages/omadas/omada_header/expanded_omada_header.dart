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
    this.gradientStart = const Color(0xFF6A11CB), // 💜 change me
    this.gradientEnd   = const Color(0xFF2575FC), // 💙 change me
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final Future<void> Function() onDiscover;
  final Future<void> Function() onRequests;
  final Future<void> Function() onCreate;

  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(
        top: OmadaTokens.space24 + 24, // breathing room for status bar
        left: OmadaTokens.space16,
        right: OmadaTokens.space16,
        bottom: OmadaTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'OMADAS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
          ),

          const SizedBox(height: OmadaTokens.space16),

          // Buttons row
          Wrap(
            spacing: OmadaTokens.space16,
            children: [
              _roundIcon(context, Icons.explore, 'Discover', onDiscover),
              _roundIcon(context, Icons.inbox_outlined, 'Requests', onRequests),
              _roundIcon(context, Icons.add, 'Create', onCreate),
            ],
          ),

          const SizedBox(height: OmadaTokens.space16),

          // Search bar UNDER the buttons (as requested)
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 213, 224, 219).withOpacity(0.52),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => onSearchChanged(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search Omadas...', // 🔤 updated text
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged();
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(
    BuildContext context,
    IconData icon,
    String tooltip,
    Future<void> Function() onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
