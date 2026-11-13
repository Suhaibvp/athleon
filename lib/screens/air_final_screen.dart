import 'package:flutter/material.dart';

import '../board.dart';
import '../widgets/board_widgets.dart';

/// 10m Final command screen from the four-event site.
class AirFinalScreen extends StatefulWidget {
  const AirFinalScreen({super.key});

  @override
  State<AirFinalScreen> createState() => _AirFinalScreenState();
}

class _AirFinalScreenState extends State<AirFinalScreen> {
  final DisplayBoard _board = DisplayBoard();

  @override
  void initState() {
    super.initState();
    _board.addListener(() => setState(() {}));
    _board.logicalBg = BoardColors.red;
    _board.paintBg = BoardColors.red;
    _board.publish();
  }

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _board.seconds != null && !_board.paused;
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          BoardHeader(onBack: () => Navigator.of(context).pop()),
          Expanded(child: Center(child: CueText(text: _board.text, seconds: _board.seconds))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _button('TAKE YOUR POSITIONS', () => _board.showText('TAKE YOUR POSITIONS', background: BoardColors.red)),
                _button('Preparation & Sighting', () => _board.startTimer('PREPARATION & SIGHTING TIME', 300, 'set_time')),
                _button('Competition Series.. LOAD', () => _board.showLoad('COMPETITION SERIES...\nLOAD')),
                _button('Competition Series.. Start', () => _board.startTimer('START', 250, 'set_time')),
                _button('Competition Shot.. LOAD', () => _board.showLoad('COMPETITION SHOT...\nLOAD')),
                _button('Competition Shot.. Start', () => _board.startTimer('START', 50, 'no_blink')),
                _button(running ? 'Stop' : 'Resume', _board.togglePause, enabled: _board.seconds != null),
                _button('Reset', () {
                  _board.reset();
                  _board.showText('', background: BoardColors.red);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed, {bool enabled = true}) {
    return SizedBox(width: 260, child: CommandButton(label: label, onPressed: onPressed, enabled: enabled, expand: false));
  }
}
