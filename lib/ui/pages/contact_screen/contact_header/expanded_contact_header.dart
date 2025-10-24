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

  const ExpandedContactHeader({
    super.key,
    required this.onManageTags,
    required this.onDiscoverUsers,
    required this.onGetRequests,
    required this.onGetDeleted,
    required this.onGetAccountPage,
    required this.onAddContact, //use this
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  State<ExpandedContactHeader> createState() => _ExpandedContactHeaderState();
}

class _ExpandedContactHeaderState extends State<ExpandedContactHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 315,
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
                    onPressed: () {
                      widget.onGetDeleted(context);
                    },
                    icon: Icon(Icons.delete),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onGetAccountPage(context);
                    },
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
                  color: Colors.grey[200]?.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    icon: Icon(Icons.person_search, color: Colors.white),
                    hintText: "Search contacts...",
                    hintStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.black),
                  onChanged: (value) => widget.onSearchChanged(),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 30,
                children: [
                  IconButton(
                    onPressed: () async {
                      widget.onManageTags();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),

                    icon: Icon(Icons.filter_list, color: Colors.white),
                    // label: Text(
                    //   "Manage Tags",
                    //   style: TextStyle(color: Colors.white),
                    // ),
                  ),

                  //discover users
                  IconButton(
                    onPressed: () async {
                      widget.onDiscoverUsers();
                    },
                    icon: Icon(Icons.search, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),

                  //request users
                  IconButton(
                    onPressed: () async {
                      widget.onGetRequests();
                    },
                    icon: Icon(Icons.person_add_alt_1, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Color.fromARGB(50, 255, 255, 255),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),

                  // ElevatedButton(
                  //   onPressed: () async {
                  //     widget.onGetRequests();
                  //   },
                  //   child: Text(
                  //     "Requests",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Color.fromARGB(50, 255, 255, 255),
                  //     elevation: 0,
                  //     shadowColor: Colors.transparent,
                  //   ),
                  // ),
                  IconButton(
                    onPressed: () async {
                      await widget.onAddContact();
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
