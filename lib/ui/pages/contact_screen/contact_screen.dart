import 'package:flutter/material.dart';
import 'package:omada/core/domain/models/tag.dart';
import 'package:omada/ui/pages/contact_screen/contact_card.dart';
import 'package:omada/ui/pages/contact_screen/contact_header/collapsed_contact_header.dart';
import 'package:omada/ui/pages/contact_screen/contact_header/expanded_contact_header.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double expandedHeight = 315;
    final double collapsedHeight = 165;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            pinned: true,

            // floating: true,
            // snap: true,
            // automaticallyImplyLeading: false,
            forceMaterialTransparency: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double currentHeight = constraints.biggest.height;

                final double t =
                    ((currentHeight - collapsedHeight) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);
                // print("reported t: $t");
                // print("current height: $currentHeight");
                // print("min height: $minHeight");
                // print(
                //   "collapsed height $collapsedHeight, $minHeight, $systemMinHeight",
                // );

                if (currentHeight > (expandedHeight + collapsedHeight) / 2) {
                  return const ExpandedContactHeader();
                } else {
                  return const CollapsedContactHeader();
                }
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
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.contacts),
    );
  }
}
