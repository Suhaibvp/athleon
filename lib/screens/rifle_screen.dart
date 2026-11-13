import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../board.dart';
import '../widgets/board_widgets.dart';

/// 10m Air Rifle command screen from the four-event site.
class RifleScreen extends StatefulWidget {
  const RifleScreen({super.key});

  @override
  State<RifleScreen> createState() => _RifleScreenState();
}

class _RifleScreenState extends State<RifleScreen> {
  final DisplayBoard _board = DisplayBoard();
  int _matchSeconds = 600;
  final _minutes = TextEditingController(text: '10');
  final _seconds = TextEditingController(text: '00');

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
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  Future<void> _editMatch() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Match time'),
        content: Row(
          children: [
            Expanded(child: TextField(controller: _minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minute'), inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':')),
            Expanded(child: TextField(controller: _seconds, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Second'), inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CLOSE')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (saved != true) return;
    final minutes = int.tryParse(_minutes.text) ?? 0;
    final seconds = int.tryParse(_seconds.text) ?? 0;
    setState(() => _matchSeconds = minutes * 60 + seconds);
  }

  @override
  Widget build(BuildContext context) {
    final running = _board.seconds != null && !_board.paused;
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          BoardHeader(
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(tooltip: 'Match time', onPressed: _editMatch, icon: const Icon(Icons.settings, size: 30)),
          ),
          Expanded(child: Center(child: CueText(text: _board.text, seconds: _board.seconds))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _button('Athletes to the Line', () => _board.showText('ATHLETES TO THE LINE', background: BoardColors.red)),
                _button('Preparation and Sighting', () => _board.startTimer('PREPARATION & SIGHTING TIME', 900, 'set_time')),
                _button('Match Firing', () => _board.startTimer('MATCH FIRING\nSTART', _matchSeconds, 'set_time')),
                _button(running ? 'Stop' : 'Resume', _board.togglePause, enabled: _board.seconds != null),
                _button('Reset', _board.reset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed, {bool enabled = true}) {
    return SizedBox(width: 240, child: CommandButton(label: label, onPressed: onPressed, enabled: enabled, expand: false));
  }
}
