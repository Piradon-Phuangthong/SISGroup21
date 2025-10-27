import 'package:flutter/material.dart';

class CollapsedContactHeader extends StatelessWidget {
  final Future<void> Function() onAddContact;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  const CollapsedContactHeader({
    super.key,
    required this.onAddContact,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF5733), // Red-orange
            Color(0xFF4A00B0), // Deep purple
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8, // Status bar height + 8
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(width: 40),
                  // Search field - takes most of the space
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => onSearchChanged(),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                            size: 20,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add button
                  IconButton(
                    onPressed: () async {
                      await onAddContact();
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color.fromARGB(50, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
