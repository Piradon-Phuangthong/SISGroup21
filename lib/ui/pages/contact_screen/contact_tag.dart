import 'package:flutter/material.dart';

class DashboardTag extends StatefulWidget {
  final String label;
  final Color color;

  const DashboardTag({super.key, required this.label, required this.color});

  @override
  State<DashboardTag> createState() => _DashboardTagtate();
}

class _DashboardTagtate extends State<DashboardTag> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: widget.color,
      ),
      child: Text(widget.label, style: TextStyle(color: Colors.white)),
    );
  }
}
