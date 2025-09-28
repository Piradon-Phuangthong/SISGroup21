import 'package:flutter/material.dart';

class CollapsedContactHeader extends StatelessWidget {
  const CollapsedContactHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/jpg/banner.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          spacing: 3,
          children: [
            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (val) {
                  print("search collpased: $val");
                },

                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search contacts...",
                  border: InputBorder.none,
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    print("filter button collpased");
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(50, 255, 255, 255),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    fixedSize: Size(250, 20),
                  ),

                  icon: Icon(Icons.filter_list, color: Colors.white),
                  label: Text(
                    "Filter by tags",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    print("add button collapsed");
                  },
                  icon: Icon(Icons.add, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Color.fromARGB(50, 255, 255, 255),
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
