import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExpandedContactHeader extends StatefulWidget {
  final Future<void> Function() onManageTags;
  final Future<void> Function() onDiscoverUsers;
  final Future<void> Function() onGetRequests;
  final void Function(BuildContext context) onGetDeleted;
  final void Function(BuildContext context) onGetAccountPage;
  final Future<void> Function() onAddContact;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final int contactCount;

  const ExpandedContactHeader({
    super.key,
    required this.onManageTags,
    required this.onDiscoverUsers,
    required this.onGetRequests,
    required this.onGetDeleted,
    required this.onGetAccountPage,
    required this.onAddContact,
    required this.onSearchChanged,
    required this.searchController,
    this.contactCount = 0,
  });

  @override
  State<ExpandedContactHeader> createState() => _ExpandedContactHeaderState();
}

class _ExpandedContactHeaderState extends State<ExpandedContactHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Settings icon
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => widget.onGetAccountPage(context),
                    icon: const Icon(Icons.settings, color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // App Title
              const Text(
                "Contacts",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Contact count
              Text(
                "${widget.contactCount} contacts",
                style: const TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                        size: 20,
                      ),
                      hintText: "Search contacts...",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (value) => widget.onSearchChanged(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.label_outline,
                    label: "New Tag",
                    color: const Color.fromARGB(255, 43, 122, 226),
                    // Color(0xFF8A2BE2)
                    onTap: widget.onManageTags,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.person_search,
                    label: "Discover",
                    color: Colors.blue,
                    onTap: widget.onDiscoverUsers,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.person_add_alt_1,
                    label: "Requests",
                    color: Colors.red,
                    onTap: widget.onGetRequests,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.add,
                    label: "Add",
                    color: Colors.orange,
                    onTap: widget.onAddContact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(50, 255, 255, 255),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
