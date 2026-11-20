import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../board.dart';
import '../widgets/board_widgets.dart';

/// 25m Rapid Fire Pistol phase timer from the four-event site.
class RapidPhaseScreen extends StatefulWidget {
  const RapidPhaseScreen({super.key});

  @override
  State<RapidPhaseScreen> createState() => _RapidPhaseScreenState();
}

class _RapidPhaseScreenState extends State<RapidPhaseScreen> {
  final DisplayBoard _board = DisplayBoard();
  final _prep = TextEditingController(text: '180');
  final _load = TextEditingController(text: '60');
  int? _prepS;
  int? _loadS;
  bool _configured = false;
  bool _advancing = false;
  bool _hint = true;

  @override
  void initState() {
    super.initState();
    _board.addListener(() {
      setState(() {});
      _advance();
    });
    _board.logicalBg = BoardColors.white;
    _board.paintBg = BoardColors.white;
    _board.publish();
  }

  @override
  void dispose() {
    _board.dispose();
    _prep.dispose();
    _load.dispose();
    super.dispose();
  }

  int _read(TextEditingController controller) => int.tryParse(controller.text) ?? 0;

  Future<void> _configure() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Match Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Preparation (s)', _prep),
            _field('Loading (s)', _load),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CLOSE')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (saved != true) return;
    setState(() {
      _prepS = _read(_prep);
      _loadS = _read(_load);
      _configured = true;
    });
  }

  void _start() {
    if (!_configured || _prepS == null) return;
    _hint = false;
    _board.startTimer('PREPARATION', _prepS!, 'phase', background: BoardColors.red);
  }

  void _advance() {
    if (_board.seconds != 0 || _advancing) return;
    final text = _board.text;
    final mode = _board.mode;
    _advancing = true;
    Future.microtask(() {
      _advancing = false;
      if (mode == 'phase' && text == 'PREPARATION') {
        _board.startTimer('LOADING', _loadS ?? 0, 'phase', background: BoardColors.yellow);
      } else if (mode == 'phase' && text == 'LOADING') {
        _board.startTimer('', 7, 'rapid7', background: BoardColors.red);
      } else if (mode == 'rapid7') {
        _board.showBlank(BoardColors.green);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _board.text;
    final running = _board.seconds != null && !_board.paused;
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          BoardHeader(
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(tooltip: 'Match Configuration', onPressed: _configure, icon: const Icon(Icons.settings, size: 30)),
          ),
          Expanded(
            child: Center(
              child: _hint && !_board.blank && _board.seconds == null
                  ? const Text('Set durations before starting', style: TextStyle(fontSize: 24, color: Colors.black54))
                  : CueText(text: text, seconds: _board.seconds),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              children: [
                CommandButton(label: 'Start Preparation', onPressed: _start, enabled: _configured && _board.seconds == null),
                CommandButton(
                  label: 'Unload',
                  onPressed: () {
                    _hint = false;
                    _board.showText('UNLOAD', background: BoardColors.red);
                  },
                ),
                CommandButton(label: running ? 'Stop' : 'Start', onPressed: _board.togglePause, enabled: _board.seconds != null),
                CommandButton(label: 'Reset', onPressed: () {
                  setState(() => _hint = true);
                  _board.showBlank(BoardColors.white);
                  _board.reset();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
