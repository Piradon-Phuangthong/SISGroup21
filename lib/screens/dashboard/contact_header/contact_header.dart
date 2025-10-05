import 'package:flutter/material.dart';
import 'package:omada/models/tag.dart';
import 'package:omada/screens/dashboard/contact_card.dart';
import 'package:omada/screens/dashboard/contact_header/collapsed_contact_header.dart';
import 'package:omada/screens/dashboard/contact_header/expanded_contact_header.dart';

class ContactHeader extends StatelessWidget {
  const ContactHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 275,
          pinned: true,
          // floating: true,
          // snap: true,
          collapsedHeight: 100,
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final double currentHeight = constraints.biggest.height;
              final double maxHeight = 301.31111111111113;
              final double minHeight = 126.3111111111111;

              final double t =
                  ((currentHeight - minHeight) / (maxHeight - minHeight)).clamp(
                    0.0,
                    1.0,
                  );
              // print("reported height: $t");
              // print("current height: $currentHeight");
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image.asset("assets/jpg/banner.jpg", fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/jpg/banner.jpg"),
                        fit: BoxFit.cover, // cover, contain, fill, etc.
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "O M A D A",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),

                  IgnorePointer(
                    ignoring: t < 0.5,
                    child: Opacity(
                      opacity: t == 1 ? 1 : 0,
                      child: Container(
                        color: Colors.blue,
                        child: const Center(child: ExpandedContactHeader()),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: t > 0.5,
                    child: Opacity(
                      opacity: t == 0 ? 1 : 0,
                      child: Container(
                        color: Colors.red,
                        child: const Center(child: CollapsedContactHeader()),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ContactCard(
              name: "name #$index",
              phone: "phone #$index",
              tags: [
                Tag("Family", 0),
                Tag("Work", 1),
                Tag("Friends", 2),
                Tag("Urgent", 3),
                Tag("School", 4),
                Tag("Fitness", 5),
              ],
              lastContact: DateTime.now(),
            ),
            childCount: 50,
          ),
        ),
      ],
    );
  }
}
