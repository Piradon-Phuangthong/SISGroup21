import 'package:flutter/material.dart';

class CollapsedContactHeader extends StatelessWidget {
  const CollapsedContactHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/jpg/banner.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8, // Status bar height + 8
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search contacts...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => print("filter button collapsed"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(50, 255, 255, 255),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    minimumSize: Size(250, 0),
                  ),
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  label: const Text(
                    "Filter by tags",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: () => print("add button collapsed"),
                  icon: const Icon(Icons.add, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color.fromARGB(50, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
