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
  final _match = TextEditingController(text: '300');
  final _stop = TextEditingController(text: '30');
  int? _prepS;
  int? _loadS;
  int? _matchS;
  int? _stopS;
  bool _configured = false;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _board.addListener(() {
      setState(() {});
      _advance();
    });
    _board.showText('Set durations before starting', background: BoardColors.white);
  }

  @override
  void dispose() {
    _board.dispose();
    _prep.dispose();
    _load.dispose();
    _match.dispose();
    _stop.dispose();
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
            _field('Match (s)', _match),
            _field('Stopping (s)', _stop),
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
      _matchS = _read(_match);
      _stopS = _read(_stop);
      _configured = true;
    });
  }

  void _start() {
    if (!_configured || _prepS == null) return;
    _board.startTimer('PREPARATION', _prepS!, 'phase', background: BoardColors.red);
  }

  void _advance() {
    if (_board.seconds != 0 || _board.mode != 'phase' || _advancing) return;
    final text = _board.text;
    _advancing = true;
    Future.microtask(() {
      _advancing = false;
      if (text == 'PREPARATION') {
        _board.startTimer('LOADING', _loadS ?? 0, 'phase', background: BoardColors.yellow);
      } else if (text == 'LOADING') {
        _board.startTimer('MATCH', _matchS ?? 0, 'phase', background: BoardColors.green);
      } else if (text == 'MATCH') {
        _board.startTimer('STOPPING', _stopS ?? 0, 'phase', background: BoardColors.red);
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
              child: text == 'Set durations before starting'
                  ? const Text('Set durations before starting', style: TextStyle(fontSize: 24, color: Colors.black54))
                  : CueText(text: text, seconds: _board.seconds),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              children: [
                CommandButton(label: 'Start Preparation', onPressed: _start, enabled: _configured && _board.seconds == null),
                CommandButton(label: running ? 'Stop' : 'Start', onPressed: _board.togglePause, enabled: _board.seconds != null),
                CommandButton(label: 'Reset', onPressed: () {
                  _board.showText('Set durations before starting', background: BoardColors.white);
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
