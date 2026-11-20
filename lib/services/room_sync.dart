import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomSync {
  RoomSync._();

  static final RoomSync instance = RoomSync._();
  static const _key = 'athleon_room_code';

  String? code;
  bool firebaseReady = false;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && RegExp(r'^\d{6}$').hasMatch(saved)) code = saved;
  }

  Future<String> create() async {
    final next = (100000 + Random().nextInt(900000)).toString();
    code = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next);
    await publish(bg: 'white', showLogo: true);
    return next;
  }

  DocumentReference<Map<String, dynamic>>? get _doc {
    final room = code;
    if (!firebaseReady || room == null) return null;
    return FirebaseFirestore.instance.collection('displayRooms').doc(room);
  }

  Future<void> publish({
    required String bg,
    String text = '',
    String foreground = 'black',
    int? seconds,
    String blink = 'none',
    bool showLogo = false,
    bool blank = false,
    String clock = 'ms',
    String weight = 'normal',
  }) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set({
        'bg': bg,
        'text': text,
        'fg': foreground,
        'seconds': seconds,
        'blink': blink,
        'showLogo': showLogo,
        'blank': blank,
        'clock': clock,
        'weight': weight,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
