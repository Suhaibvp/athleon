import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/room_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: athleonFirebaseOptions);
    RoomSync.instance.firebaseReady = true;
  } catch (_) {}
  await RoomSync.instance.restore();
  runApp(const AthleonApp());
}

class AthleonApp extends StatelessWidget {
  const AthleonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athleon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      home: const SplashScreen(),
    );
  }
}
