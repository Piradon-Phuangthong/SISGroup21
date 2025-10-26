import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';

class CollapsedOmadaHeader extends StatelessWidget {
  const CollapsedOmadaHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCreate,
    this.gradientStart = const Color(0xFF6A11CB), // 💜 change me
    this.gradientEnd   = const Color(0xFF2575FC), // 💙 change me
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
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
        top: OmadaTokens.space24 + 8,
        left: OmadaTokens.space16,
        right: OmadaTokens.space16,
        bottom: OmadaTokens.space12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search Omadas', // 🔤 updated text
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
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: OmadaTokens.space8),
          FloatingActionButton.small(
            heroTag: 'fab-omada-collapsed',
            onPressed: () => onCreate(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
