import 'package:flutter/material.dart';
import 'package:omada/screens/dashboard/contact_header/contact_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // return Scaffold(body: DashboardBanner());
    // return Scaffold(body: CollapsibleHeaderDemo());
    // return Scaffold(body: ExamplePage());
    return Scaffold(body: ContactHeader());
  }
}
