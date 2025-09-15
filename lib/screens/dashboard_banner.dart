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
    return Column(
      children: [
        Container(
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
        ),

        //Contact tiles, i factorise later
        Expanded(
          child: Center(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                //each of these will be copy pasted of what will eventually become factorised list tile
                Row(
                  children: [
                    //avatar photo
                    Icon(Icons.person),

                    //contact information
                    Column(
                      children: [
                        Text("Name"),
                        Text("+123456789"),
                        Row(
                          //tags
                          children: [
                            Container(
                              color: Colors.red,
                              child: Text(
                                "Family",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Container(
                              color: Colors.blue,
                              child: Text(
                                "Work",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        Text(
                          "Last contact: Jan 1, 11:11 AM",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),

                    // message/phone
                    Row(
                      children: [
                        IconButton(onPressed: () {}, icon: Icon(Icons.phone)),
                        IconButton(onPressed: () {}, icon: Icon(Icons.message)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
