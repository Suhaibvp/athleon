import 'dart:async';

import 'package:flutter/material.dart';

import 'services/room_sync.dart';

class BoardColors {
  static const white = Colors.white;
  static const red = Color(0xFFCC1313);
  static const green = Color(0xFF4CAF50);
  static const yellow = Color(0xFFFFEB3B);
  static const tile = Color(0xFF212121);
  static const blue = Color(0xFF2196F3);
  static const black54 = Color(0x8A000000);

  static String nameOf(Color color) {
    if (color == red) return 'red';
    if (color == green) return 'green';
    if (color == yellow) return 'yellow';
    return 'white';
  }

  static Color fromName(String name) {
    switch (name) {
      case 'red':
        return red;
      case 'green':
        return green;
      case 'yellow':
        return yellow;
      default:
        return white;
    }
  }
}

String formatClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remain = (safe % 60).toString().padLeft(2, '0');
  return '$minutes:$remain';
}

int parseClock(String value) {
  try {
    final parts = value.split(':');
    if (parts.length == 2) {
      final minutes = int.parse(parts[0].trim());
      final seconds = int.parse(parts[1].trim());
      return minutes * 60 + seconds;
    }
  } catch (_) {}
  return 60;
}

/// The colored command screen shared by the finals board and the pistol boards.
class DisplayBoard extends ChangeNotifier {
  Color logicalBg = BoardColors.white;
  Color paintBg = BoardColors.white;
  String? text;
  int? seconds;
  int? total;
  String? mode;
  bool paused = false;
  bool timesReady = false;
  String blink = 'none';

  Timer? _tick;
  Timer? _blink;
  bool _blinkOnGreen = true;

  bool get showLogo => text == null && seconds == null;

  void showText(String value, {Color? background}) {
    _stopTick();
    _stopBlink();
    text = value;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    if (background != null) logicalBg = background;
    paintBg = logicalBg;
    notifyListeners();
    publish();
  }

  void showLoad(String value) => showText(value, background: BoardColors.yellow);

  void startTimer(String value, int totalSeconds, String timerMode, {Color? background}) {
    _stopTick();
    _stopBlink();
    text = value.isEmpty ? null : value;
    seconds = totalSeconds;
    total = totalSeconds;
    mode = timerMode;
    paused = false;
    logicalBg = background ?? BoardColors.green;
    paintBg = logicalBg;
    notifyListeners();
    publish();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void togglePause() {
    if (seconds == null) return;
    paused = !paused;
    notifyListeners();
    publish();
  }

  void reset() {
    if (total != null && mode != null) {
      startTimer(text ?? '', total!, mode!);
      return;
    }
    _stopTick();
    _stopBlink();
    text = null;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    logicalBg = timesReady ? BoardColors.red : BoardColors.white;
    paintBg = logicalBg;
    notifyListeners();
    publish();
  }

  void setReady(bool ready) {
    timesReady = ready;
    if (ready) {
      _stopBlink();
      logicalBg = BoardColors.red;
      paintBg = BoardColors.red;
    }
    notifyListeners();
    publish();
  }

  void _onTick() {
    if (paused) return;
    final left = seconds;
    if (left == null) return;
    if (left > 0) {
      seconds = left - 1;
      if (seconds == 30 && blink == 'none') {
        if (mode == 'set_time') _startBlink('setTime');
        if (mode == 'change_over') _startBlink('changeOver');
      }
      notifyListeners();
      publish();
      return;
    }
    _stopTick();
    _stopBlink();
    text = null;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    logicalBg = BoardColors.red;
    paintBg = BoardColors.red;
    notifyListeners();
    publish();
  }

  void _startBlink(String kind) {
    blink = kind;
    _blinkOnGreen = true;
    paintBg = BoardColors.green;
    _blink?.cancel();
    _blink = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _blinkOnGreen = !_blinkOnGreen;
      if (blink == 'setTime') {
        paintBg = _blinkOnGreen ? BoardColors.green : BoardColors.white;
      } else {
        paintBg = _blinkOnGreen ? BoardColors.green : BoardColors.red;
      }
      notifyListeners();
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
  }

  void _stopBlink() {
    _blink?.cancel();
    _blink = null;
    blink = 'none';
  }

  Future<void> publish() {
    return RoomSync.instance.publish(
      bg: BoardColors.nameOf(logicalBg),
      text: text ?? '',
      seconds: seconds,
      blink: blink,
      showLogo: showLogo,
    );
  }

  @override
  void dispose() {
    _stopTick();
    _stopBlink();
    super.dispose();
  }
}
