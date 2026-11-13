import 'package:flutter/material.dart';

import '../board.dart';
import '../services/saved_times.dart';
import '../widgets/board_widgets.dart';

class FinalsScreen extends StatefulWidget {
  const FinalsScreen({super.key});

  @override
  State<FinalsScreen> createState() => _FinalsScreenState();
}

class _FinalsScreenState extends State<FinalsScreen> {
  final DisplayBoard _board = DisplayBoard();
  final _prepMin = TextEditingController(text: '00');
  final _prepSec = TextEditingController(text: '00');
  final _changeMin = TextEditingController(text: '00');
  final _changeSec = TextEditingController(text: '00');
  final _setMin = TextEditingController(text: '00');
  final _setSec = TextEditingController(text: '00');

  String? _prep;
  String? _change;
  String? _setTime;
  int? _setSeconds;
  bool _settings = false;
  bool _setPanel = false;

  @override
  void initState() {
    super.initState();
    _board.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    final saved = await SavedTimes.finals();
    if (!mounted) return;
    _applyClock(_prepMin, _prepSec, saved.prep);
    _applyClock(_changeMin, _changeSec, saved.change);
    _applyClock(_setMin, _setSec, saved.setTime);
    setState(() {
      _prep = saved.prep;
      _change = saved.change;
      _setTime = saved.setTime;
      _setSeconds = saved.setTime == null ? null : parseClock(saved.setTime!);
    });
    if (saved.prep != null && saved.prep!.isNotEmpty && saved.change != null && saved.change!.isNotEmpty) {
      _board.setReady(true);
      return;
    }
    await _board.publish();
  }

  void _applyClock(TextEditingController minutes, TextEditingController seconds, String? value) {
    if (value == null || !value.contains(':')) return;
    final parts = value.split(':');
    if (parts.length != 2) return;
    minutes.text = parts[0];
    seconds.text = parts[1];
  }

  @override
  void dispose() {
    _board.dispose();
    _prepMin.dispose();
    _prepSec.dispose();
    _changeMin.dispose();
    _changeSec.dispose();
    _setMin.dispose();
    _setSec.dispose();
    super.dispose();
  }

  String? _join(TextEditingController minutes, TextEditingController seconds) {
    if (minutes.text.isEmpty || seconds.text.isEmpty) return null;
    return '${minutes.text}:${seconds.text.padLeft(2, '0')}';
  }

  void _closeSettings() {
    _applyClock(_prepMin, _prepSec, _prep);
    _applyClock(_changeMin, _changeSec, _change);
    setState(() => _settings = false);
  }

  Future<void> _saveSettings() async {
    final prep = _join(_prepMin, _prepSec);
    final change = _join(_changeMin, _changeSec);
    setState(() {
      if (prep != null) _prep = prep;
      if (change != null) _change = change;
      _settings = false;
    });
    await SavedTimes.saveFinals(prep: prep, change: change);
    if (prep != null && change != null) _board.setReady(true);
  }

  void _closeSetTime() {
    _applyClock(_setMin, _setSec, _setTime);
    setState(() => _setPanel = false);
  }

  Future<void> _saveSetTime() async {
    final value = _join(_setMin, _setSec);
    if (value == null) {
      setState(() => _setPanel = false);
      return;
    }
    setState(() {
      _setTime = value;
      _setSeconds = parseClock(value);
      _setPanel = false;
    });
    await SavedTimes.saveFinals(setTime: value);
  }

  @override
  Widget build(BuildContext context) {
    final running = _board.seconds != null && !_board.paused;
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          _header(),
          if (_settings) _settingsCard(),
          if (_setPanel) _setCard(),
          Expanded(child: Center(child: CueText(text: _board.text, seconds: _board.seconds))),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    CommandButton(label: 'ATHLETES TO LINE', onPressed: () => _board.showText('ATHLETES TO LINE')),
                    const SizedBox(width: 4),
                    CommandButton(
                      label: 'PREPARATION &SIGHTING',
                      enabled: _board.timesReady && _prep != null,
                      onPressed: () => _board.startTimer('PREPARATION &SIGHTING', parseClock(_prep!), 'preparation'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CommandButton(
                      label: 'FOR NEXT COMPETITION SERIES LOAD',
                      onPressed: () => _board.showLoad('FOR NEXT COMPETITION SERIES LOAD'),
                    ),
                    CommandButton(
                      label: 'FIRST COMPETITION SERIES LOAD',
                      onPressed: () => _board.showLoad('FIRST COMPETITION SERIES LOAD'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CommandButton(
                      label: _setTime == null ? 'SET TIME\nEACH TIME' : 'SET TIME\nTIME: $_setTime',
                      onPressed: () => setState(() {
                        _setPanel = !_setPanel;
                        _settings = false;
                      }),
                    ),
                    CommandButton(
                      label: 'START',
                      enabled: _setSeconds != null,
                      onPressed: () => _board.startTimer('', _setSeconds!, 'set_time'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CommandButton(
                      label: 'START',
                      enabled: _board.timesReady && _change != null,
                      onPressed: () => _board.startTimer(
                        'CHANGE OVER AND SIGHTING TIME',
                        parseClock(_change!),
                        'change_over',
                      ),
                    ),
                    CommandButton(
                      label: 'CHANGE OVER AND SIGHTING TIME',
                      onPressed: () => _board.showText('CHANGE OVER AND SIGHTING TIME'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CommandButton(
                      label: 'FOR NEXT COMPETITION SHOT LOAD',
                      onPressed: () => _board.showLoad('FOR NEXT COMPETITION SHOT LOAD'),
                    ),
                    CommandButton(label: 'START 50SEC', onPressed: () => _board.startTimer('', 50, 'no_blink')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CommandButton(
                      label: running ? 'STOP' : 'START',
                      enabled: _board.seconds != null,
                      onPressed: _board.togglePause,
                    ),
                    const SizedBox(width: 8),
                    CommandButton(label: 'RESET', onPressed: _board.reset),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return BoardHeader(
      onBack: () => Navigator.of(context).pop(),
      trailing: IconButton(
        tooltip: 'Settings',
        onPressed: () {
          if (_settings) {
            _closeSettings();
            return;
          }
          setState(() {
            _settings = true;
            _setPanel = false;
          });
        },
        icon: const Icon(Icons.settings, size: 30, color: Colors.black),
      ),
    );
  }

  Widget _settingsCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsCard(
        title: 'SETTINGS',
        child: Column(
          children: [
            TimePair(label: 'PREPARATION &SIGHTING', minutes: _prepMin, seconds: _prepSec),
            const SizedBox(height: 12),
            TimePair(label: 'CHANGE OVER AND SIGHTING', minutes: _changeMin, seconds: _changeSec),
            const SizedBox(height: 16),
            CloseSaveRow(onClose: _closeSettings, onSave: _saveSettings),
          ],
        ),
      ),
    );
  }

  Widget _setCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsCard(
        title: 'SET TIME',
        width: 300,
        child: Column(
          children: [
            TimePair(label: 'EACH TIME', minutes: _setMin, seconds: _setSec, fieldWidth: 60, fontSize: 18),
            const SizedBox(height: 16),
            CloseSaveRow(onClose: _closeSetTime, onSave: _saveSetTime),
          ],
        ),
      ),
    );
  }
}
