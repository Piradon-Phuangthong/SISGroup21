import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fill the whole screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5F6D), // red-pinkish tone
              Color(0xFF0D47A1), // deep blue
            ],
          ),
        ),
        child: const Center(
          child: Text(
            "Omada",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: "Roboto", // or your custom font if added
            ),
          ),
        ),
      ),
    );
  }
}
