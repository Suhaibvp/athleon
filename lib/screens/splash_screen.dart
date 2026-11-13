import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/board_widgets.dart';
import 'client_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final room = Uri.base.queryParameters['room'];
      final next = room != null && RegExp(r'^\d{6}$').hasMatch(room)
          ? ClientView(code: room)
          : const HomeScreen();
      Navigator.of(context).pushReplacement(slidePage(next));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 200, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 8),
            const Text('ATHLEON', style: TextStyle(fontFamily: 'EurostileExtendedBlack', fontSize: 32)),
          ],
        ),
      ),
    );
  }
}
