import 'dart:async';

import 'package:flutter/material.dart';

import 'services/room_sync.dart';

class BoardColors {
  static const white = Colors.white;
  static const red = Color(0xFFCC1313);
  static const green = Color(0xFF4CAF50);
  static const yellow = Color(0xFFFFEB3B);
  static const orange = Color(0xFFFF9800);
  static const tile = Color(0xFF212121);
  static const blue = Color(0xFF2196F3);
  static const black54 = Color(0x8A000000);

  static String nameOf(Color color) {
    if (color == red) return 'red';
    if (color == green) return 'green';
    if (color == yellow) return 'yellow';
    if (color == orange) return 'orange';
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
      case 'orange':
        return orange;
      default:
        return white;
    }
  }
}

String formatClock(int seconds, {bool hours = false}) {
  final safe = seconds < 0 ? 0 : seconds;
  if (hours) {
    final hour = safe ~/ 3600;
    final minutes = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
    final remain = (safe % 60).toString().padLeft(2, '0');
    return '$hour:$minutes:$remain';
  }
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
  Color textColor = Colors.black;
  bool blank = false;
  String? text;
  int? seconds;
  int? total;
  String? mode;
  bool paused = false;
  bool timesReady = false;
  bool heavy = false;
  String blink = 'none';

  Timer? _tick;
  Timer? _blink;
  bool _blinkOnGreen = true;

  bool get showLogo => !blank && text == null && seconds == null;

  void showText(String value, {Color? background, Color? foreground}) {
    _stopTick();
    _stopBlink();
    text = value;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    textColor = foreground ?? Colors.black;
    blank = false;
    _matchBlinkFloor = null;
    if (background != null) logicalBg = background;
    paintBg = logicalBg;
    notifyListeners();
    publish();
  }

  void showLoad(String value) => showText(value, background: BoardColors.yellow);

  void startTimer(String value, int totalSeconds, String timerMode, {Color? background, Color? foreground}) {
    _stopTick();
    _stopBlink();
    text = value.isEmpty ? null : value;
    seconds = totalSeconds;
    total = totalSeconds;
    mode = timerMode;
    paused = false;
    blank = false;
    _matchBlinkFloor = null;
    textColor = foreground ?? Colors.black;
    logicalBg = background ?? BoardColors.green;
    paintBg = logicalBg;
    _syncBlink();
    notifyListeners();
    publish();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void showBlank(Color background) {
    _stopTick();
    _stopBlink();
    text = null;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    blank = true;
    _matchBlinkFloor = null;
    textColor = Colors.black;
    logicalBg = background;
    paintBg = background;
    notifyListeners();
    publish();
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
    textColor = Colors.black;
    blank = false;
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
      if (mode == 'match' && seconds == 0) {
        showText('STOP', background: BoardColors.red);
        return;
      }
      _syncBlink();
      notifyListeners();
      publish();
      return;
    }
    if (mode == 'match') {
      showText('STOP', background: BoardColors.red);
      return;
    }
    _stopTick();
    _stopBlink();
    text = null;
    seconds = null;
    total = null;
    mode = null;
    paused = false;
    textColor = Colors.black;
    blank = false;
    logicalBg = BoardColors.red;
    paintBg = BoardColors.red;
    notifyListeners();
    publish();
  }

  void _syncBlink() {
    final left = seconds;
    if (left == null || left <= 0) return;
    if (mode == 'prep' && left <= 30 && blink == 'none') {
      _startBlink('setTime');
      return;
    }
    if (mode != 'match') return;
    if (left == 600) _matchBlinkFloor = 570;
    if (left == 300) _matchBlinkFloor = 270;
    final floor = _matchBlinkFloor;
    if (floor != null && left <= floor) {
      _matchBlinkFloor = null;
      _stopBlink();
      paintBg = logicalBg;
      return;
    }
    if (floor != null && blink == 'none') _startBlink('setTime');
  }

  int? _matchBlinkFloor;

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
      foreground: textColor == Colors.white ? 'white' : 'black',
      seconds: seconds,
      blink: blink,
      showLogo: showLogo,
      blank: blank,
      clock: mode == 'match' ? 'hms' : 'ms',
      weight: heavy ? 'heavy' : 'normal',
    );
  }

  @override
  void dispose() {
    _stopTick();
    _stopBlink();
    super.dispose();
  }
}
