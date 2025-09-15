import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DashboardBanner extends StatefulWidget {
  const DashboardBanner({super.key});

  @override
  State<DashboardBanner> createState() => _DashboardBannerState();
}

class _DashboardBannerState extends State<DashboardBanner> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/jpg/banner.jpg"),
          fit: BoxFit.cover, // cover, contain, fill, etc.
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            spacing: 20,
            children: [
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
                    onPressed: () {},
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
                    onPressed: () {},
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
