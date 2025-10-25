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
      height: 120,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200]?.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          icon: Icon(Icons.person_search, color: Colors.white),
                          hintText: "Search contacts...",
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.black),
                        onChanged: (value) => onSearchChanged(),
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
