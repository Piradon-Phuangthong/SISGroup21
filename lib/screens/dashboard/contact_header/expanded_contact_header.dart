import 'package:flutter/material.dart';

class ExpandedContactHeader extends StatefulWidget {
  const ExpandedContactHeader({super.key});

  @override
  State<ExpandedContactHeader> createState() => _ExpandedContactHeaderState();
}

class _ExpandedContactHeaderState extends State<ExpandedContactHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/jpg/banner.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            spacing: 20,
            children: [
              Row(
                children: [
                  Expanded(child: SizedBox()),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.person),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              Text(
                "OMADA",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 30,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      print("filter button expanded");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),

                    icon: Icon(Icons.filter_list, color: Colors.white),
                    label: Text(
                      "Filter by tags",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      print("add button expanded");
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
      ),
    );
  }
}
