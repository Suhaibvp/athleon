import 'package:flutter/material.dart';

class LogoPage extends StatelessWidget {
  const LogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/ATHLEON.jpg', fit: BoxFit.contain),
          Positioned(
            left: 16,
            bottom: 16,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 40, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
