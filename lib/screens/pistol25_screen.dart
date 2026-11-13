import 'dart:async';

import 'package:flutter/material.dart';

import '../board.dart';
import '../services/saved_times.dart';
import '../widgets/board_widgets.dart';

enum _Step {
  idle,
  prep,
  sighting,
  attentionToStart,
  start,
  stop,
  unloadToSeries,
  series,
  attentionAfterSeries,
  unloadToMalfunction,
  malfunction,
  attentionAfterMalfunction,
  unloadToProve,
  prove,
}

class Pistol25Screen extends StatefulWidget {
  const Pistol25Screen({super.key});

  @override
  State<Pistol25Screen> createState() => _Pistol25ScreenState();
}

class _Pistol25ScreenState extends State<Pistol25Screen> {
  static const _key = 'pistol25_flow';
  static const _sightingSeconds = 60;
  static const _attentionSeconds = 7;
  static const _stopSeconds = 5;
  static const _unloadSeconds = 10;

  final DisplayBoard _board = DisplayBoard();
  final _prepMin = TextEditingController();
  final _prepSec = TextEditingController();
  final _startMin = TextEditingController();
  final _startSec = TextEditingController();
  final _seriesMin = TextEditingController();
  final _seriesSec = TextEditingController();
  final _malMin = TextEditingController();
  final _malSec = TextEditingController();

  List<int> _saved = [0, 0, 0, 0];
  _Step _step = _Step.idle;
  bool _busy = false;
  bool _warnOn = true;
  int _run = 0;
  Timer? _warnTick;

  @override
  void initState() {
    super.initState();
    _board.addListener(_onBoard);
    _board.logicalBg = BoardColors.yellow;
    _board.paintBg = BoardColors.yellow;
    _load();
  }

  bool get _configured => _saved.every((value) => value > 0);

  int get _prepSeconds => _saved[0];
  int get _startSeconds => _saved[1];
  int get _seriesSeconds => _saved[2];
  int get _malSeconds => _saved[3];

  Future<void> _load() async {
    final values = await SavedTimes.ints(_key, [0, 0, 0, 0]);
    if (!mounted) return;
    setState(() => _saved = values);
    _fillControllers(values);
    _syncWarning();
    await _board.publish();
  }

  void _fillControllers(List<int> values) {
    _writeClock(_prepMin, _prepSec, values[0]);
    _writeClock(_startMin, _startSec, values[1]);
    _writeClock(_seriesMin, _seriesSec, values[2]);
    _writeClock(_malMin, _malSec, values[3]);
  }

  void _writeClock(TextEditingController minutes, TextEditingController seconds, int total) {
    if (total <= 0) {
      minutes.text = '';
      seconds.text = '';
      return;
    }
    minutes.text = (total ~/ 60).toString().padLeft(2, '0');
    seconds.text = (total % 60).toString().padLeft(2, '0');
  }

  int _readClock(TextEditingController minutes, TextEditingController seconds) {
    final mins = int.tryParse(minutes.text) ?? 0;
    final secs = int.tryParse(seconds.text) ?? 0;
    return mins * 60 + secs;
  }

  void _syncWarning() {
    if (_configured) {
      _warnTick?.cancel();
      _warnTick = null;
      return;
    }
    _warnTick ??= Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() => _warnOn = !_warnOn);
    });
  }

  void _onBoard() {
    setState(() {});
    if (_board.seconds != 0 || _busy) return;
    final step = _step;
    final run = _run;
    _busy = true;
    Future.microtask(() {
      _busy = false;
      if (!mounted || run != _run) return;
      _advance(step);
    });
  }

  void _advance(_Step step) {
    switch (step) {
      case _Step.prep:
        _beginSighting();
      case _Step.sighting:
        _beginAttention(_Step.attentionToStart);
      case _Step.attentionToStart:
        _beginStart();
      case _Step.start:
        _beginStop();
      case _Step.stop:
        _beginUnload(_Step.unloadToSeries);
      case _Step.unloadToSeries:
        _beginSeries();
      case _Step.series:
        _beginAttention(_Step.attentionAfterSeries);
      case _Step.attentionAfterSeries:
        _beginUnload(_Step.unloadToMalfunction);
      case _Step.unloadToMalfunction:
        _beginMalfunction();
      case _Step.malfunction:
        _beginAttention(_Step.attentionAfterMalfunction);
      case _Step.attentionAfterMalfunction:
        _beginUnload(_Step.unloadToProve);
      case _Step.unloadToProve:
        _showProve();
      case _Step.idle:
      case _Step.prove:
        break;
    }
  }

  void _show(String text, {Color background = BoardColors.yellow}) {
    _board.showText(text, background: background);
  }

  void _count(String text, int seconds, _Step step, {Color background = BoardColors.yellow}) {
    _step = step;
    _board.startTimer(text, seconds, 'no_blink', background: background);
  }

  bool _guardTimed() {
    if (_configured) return true;
    _openSettings();
    return false;
  }

  void _beginPrep() {
    if (!_guardTimed()) return;
    _count('PREPARATION TIME BEGINS NOW', _prepSeconds, _Step.prep);
  }

  void _beginSighting() {
    if (!_guardTimed()) return;
    _count('FOR THE SIGHTING SERIES - LOAD', _sightingSeconds, _Step.sighting);
  }

  void _beginAttention(_Step step) {
    if (!_guardTimed()) return;
    _count('ATTENTION', _attentionSeconds, step, background: BoardColors.red);
  }

  void _beginStart() {
    if (!_guardTimed()) return;
    _count('START', _startSeconds, _Step.start);
  }

  void _beginStop() {
    if (!_guardTimed()) return;
    _count('STOP', _stopSeconds, _Step.stop);
  }

  void _beginUnload(_Step step) {
    if (!_guardTimed()) return;
    _count('UNLOAD', _unloadSeconds, step);
  }

  void _beginSeries() {
    if (!_guardTimed()) return;
    _count('FOR THE NEXT COMPETITION SERIES – LOAD', _seriesSeconds, _Step.series);
  }

  void _beginMalfunction() {
    if (!_guardTimed()) return;
    _count('FOR THE MALFUNCTION SERIES – LOAD', _malSeconds, _Step.malfunction);
  }

  void _showProve() {
    _step = _Step.prove;
    _show('This relay has ended. PROVE PISTOL');
  }

  void _reset() {
    _run++;
    _step = _Step.idle;
    _show('');
  }

  Future<void> _openSettings() async {
    _fillControllers(_saved);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('SETTINGS', style: TextStyle(color: BoardColors.green, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimePair(label: 'PREPARATION', minutes: _prepMin, seconds: _prepSec),
              const SizedBox(height: 12),
              TimePair(label: 'START', minutes: _startMin, seconds: _startSec),
              const SizedBox(height: 12),
              TimePair(label: 'NEXT COMPETITION SERIES', minutes: _seriesMin, seconds: _seriesSec),
              const SizedBox(height: 12),
              TimePair(label: 'MALFUNCTION SERIES', minutes: _malMin, seconds: _malSec),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('CLOSE'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: BoardColors.green),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (saved != true) {
      _fillControllers(_saved);
      return;
    }
    final next = [
      _readClock(_prepMin, _prepSec),
      _readClock(_startMin, _startSec),
      _readClock(_seriesMin, _seriesSec),
      _readClock(_malMin, _malSec),
    ];
    if (next.any((value) => value <= 0)) {
      _fillControllers(_saved);
      return;
    }
    setState(() => _saved = next);
    _syncWarning();
    await SavedTimes.saveInts(_key, next);
  }

  @override
  void dispose() {
    _run++;
    _warnTick?.cancel();
    _board.removeListener(_onBoard);
    _board.dispose();
    _prepMin.dispose();
    _prepSec.dispose();
    _startMin.dispose();
    _startSec.dispose();
    _seriesMin.dispose();
    _seriesSec.dispose();
    _malMin.dispose();
    _malSec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          BoardHeader(
            onBack: () => Navigator.of(context).pop(),
            trailing: IconButton(
              tooltip: 'Settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.settings, size: 30, color: Colors.black),
            ),
          ),
          if (!_configured)
            AnimatedOpacity(
              opacity: _warnOn ? 1 : 0.15,
              duration: const Duration(milliseconds: 200),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'SET THE TIMERS',
                  style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          Expanded(child: Center(child: CueText(text: _board.text, seconds: _board.seconds))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _button('ATHLETE TO THE LINE', () {
                  _step = _Step.idle;
                  _show('Athlete to the line');
                }),
                _button('UNBOX & HANDLE', () {
                  _step = _Step.idle;
                  _show('You can unbox & handle your Pistols. Safety flags must be inserted in the pistols. Holding & Aiming exercise is allowed.');
                }),
                _button('PREPARATION TIME', _beginPrep),
                _button('SIGHTING SERIES LOAD', _beginSighting),
                _button('ATTENTION', () => _beginAttention(_Step.attentionToStart)),
                _button('START', _beginStart),
                _button('STOP', _beginStop),
                _button('UNLOAD', () => _beginUnload(_Step.unloadToSeries)),
                _button('FIRST COMPETITION SERIES LOAD', () {
                  _step = _Step.idle;
                  _show('FOR THE FIRST COMPETITION SERIES – LOAD');
                }),
                _button('NEXT COMPETITION SERIES LOAD', _beginSeries),
                _button('MALFUNCTION SERIES', _beginMalfunction),
                _button('PROVE PISTOL', _showProve),
                _button('RESET', _reset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(width: 250, child: CommandButton(label: label, onPressed: onPressed, expand: false));
  }
}
