import 'package:flutter/material.dart';

class CollapsedOmadaHeader extends StatelessWidget {
  const CollapsedOmadaHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCreate,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final VoidCallback onCreate;

  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // cap width so the pill is shorter than full row
    final searchWidth = screenW * 0.82; // ~82% of row

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
          // a little more top padding so it sits lower
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            children: [
              // Shorter pill search (fixed max width + centered)
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => onSearchChanged(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search Omadas...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              // Plus button
              InkWell(
                onTap: onCreate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
