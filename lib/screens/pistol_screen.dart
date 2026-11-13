import 'package:flutter/material.dart';

import '../board.dart';
import '../services/room_sync.dart';
import '../services/saved_times.dart';
import '../widgets/board_widgets.dart';
import 'logo_page.dart';

enum PistolEvent { pistol, rapid, standard }

class PistolScreen extends StatefulWidget {
  const PistolScreen({super.key, required this.event});

  final PistolEvent event;

  @override
  State<PistolScreen> createState() => _PistolScreenState();
}

class _Slide {
  const _Slide(this.display, {this.button, this.load = false, this.timeIndex});

  final String display;
  final String? button;
  final bool load;
  final int? timeIndex;

  String get label => button ?? display;
}

class _SliderSpec {
  const _SliderSpec(this.label, this.min, this.max);

  final String label;
  final int min;
  final int max;
}

class _PistolScreenState extends State<PistolScreen> {
  final DisplayBoard _board = DisplayBoard();
  late List<int> _saved;
  late List<int> _draft;
  bool _settings = false;

  static const _rapidDefaults = [8, 8, 6, 4];
  static const _standardDefaults = [150, 150, 20, 10];
  static const _rapidSliders = [
    _SliderSpec('SIGHTING SERIES', 1, 30),
    _SliderSpec('8 SECONDS SERIES', 1, 30),
    _SliderSpec('6 SECONDS SERIES', 1, 30),
    _SliderSpec('4 SECONDS SERIES', 1, 30),
  ];
  static const _standardSliders = [
    _SliderSpec('SIGHTING SERIES', 5, 300),
    _SliderSpec('150 SECONDS SERIES', 5, 300),
    _SliderSpec('20 SECONDS SERIES', 5, 60),
    _SliderSpec('10 SECONDS SERIES', 5, 60),
  ];

  static const _unbox =
      'You can unbox & handle your Pistols. Safety flags must be inserted in the pistols. Holding & Aiming exercise is allowed.';

  @override
  void initState() {
    super.initState();
    _saved = List.of(_defaults);
    _draft = List.of(_defaults);
    _board.addListener(() => setState(() {}));
    _load();
  }

  List<int> get _defaults => widget.event == PistolEvent.standard ? _standardDefaults : _rapidDefaults;

  List<_SliderSpec> get _specs => widget.event == PistolEvent.standard ? _standardSliders : _rapidSliders;

  Future<void> _load() async {
    if (widget.event == PistolEvent.pistol) {
      await _board.publish();
      return;
    }
    final key = widget.event == PistolEvent.rapid ? SavedTimes.rapidKey : SavedTimes.standardKey;
    final values = await SavedTimes.ints(key, _defaults);
    if (!mounted) return;
    setState(() {
      _saved = values;
      _draft = List.of(values);
    });
    await _board.publish();
  }

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  List<_Slide> get _slides {
    switch (widget.event) {
      case PistolEvent.pistol:
        return const [
          _Slide('Athlete to the line', button: 'ATHLETE TO THE LINE'),
          _Slide(_unbox, button: 'UNBOX & HANDLE'),
          _Slide('PREPARATION TIME BEGINS NOW'),
          _Slide('FOR THE SIGHTING SERIES - LOAD', load: true),
          _Slide('ATTENTION'),
          _Slide('UNLOAD'),
          _Slide('FOR THE FIRST COMPETITION SERIES – LOAD', load: true),
          _Slide('ATTENTION'),
          _Slide('UNLOAD'),
          _Slide('FOR THE NEXT COMPETITION SERIES – LOAD', load: true),
          _Slide('ATTENTION'),
          _Slide('UNLOAD'),
          _Slide('This relay has ended. PROVE PISTOL', button: 'PROVE PISTOL'),
        ];
      case PistolEvent.rapid:
        return [
          const _Slide('Athlete to the line', button: 'ATHLETE TO THE LINE'),
          const _Slide(_unbox, button: 'UNBOX & HANDLE'),
          const _Slide('PREPARATION TIME BEGINS NOW'),
          _Slide('${_saved[0]} SECONDS - SIGHTING SERIES- LOAD', load: true, timeIndex: 0),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[1]} SECONDS SERIES– LOAD', load: true, timeIndex: 1),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[2]} SECONDS SERIES– LOAD', load: true, timeIndex: 2),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[3]} SECONDS SERIES– LOAD', load: true, timeIndex: 3),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          const _Slide('This relay has ended. PROVE PISTOL', button: 'PROVE PISTOL'),
        ];
      case PistolEvent.standard:
        return [
          const _Slide('Athlete to the line', button: 'ATHLETE TO THE LINE'),
          const _Slide(_unbox, button: 'UNBOX & HANDLE'),
          const _Slide('PREPARATION TIME BEGINS NOW'),
          _Slide('${_saved[0]} SECONDS - SIGHTING SERIES - LOAD', load: true, timeIndex: 0),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[1]} SECONDS SERIES– LOAD', load: true, timeIndex: 1),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[2]} SECONDS SERIES– LOAD', load: true, timeIndex: 2),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          _Slide('${_saved[3]} SECONDS SERIES– LOAD', load: true, timeIndex: 3),
          const _Slide('ATTENTION'),
          const _Slide('UNLOAD'),
          const _Slide('This relay has ended. PROVE PISTOL', button: 'PROVE PISTOL'),
        ];
    }
  }

  void _press(_Slide slide) {
    final index = slide.timeIndex;
    if (index != null) {
      final seconds = _saved[index];
      _board.startTimer(slide.display, seconds, seconds > 30 ? 'set_time' : 'no_blink');
      return;
    }
    if (slide.load) {
      _board.showLoad(slide.display);
      return;
    }
    _board.showText(slide.display);
  }

  void _closeSettings() {
    setState(() {
      _draft = List.of(_saved);
      _settings = false;
    });
  }

  Future<void> _saveSettings() async {
    final next = List<int>.of(_draft);
    setState(() {
      _saved = next;
      _settings = false;
    });
    final key = widget.event == PistolEvent.rapid ? SavedTimes.rapidKey : SavedTimes.standardKey;
    await SavedTimes.saveInts(key, next);
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final rows = <Widget>[];
    for (var i = 0; i < slides.length; i += 2) {
      rows.add(const SizedBox(height: 8));
      rows.add(
        Row(
          children: [
            CommandButton(label: slides[i].label, onPressed: () => _press(slides[i])),
            if (i + 1 < slides.length)
              CommandButton(label: slides[i + 1].label, onPressed: () => _press(slides[i + 1]))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    final running = _board.seconds != null && !_board.paused;
    return Scaffold(
      backgroundColor: _board.paintBg,
      body: Column(
        children: [
          _header(),
          Expanded(flex: 3, child: Center(child: CueText(text: _board.text, seconds: _board.seconds))),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                children: [
                  if (_settings) _settingsCard(),
                  ...rows,
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
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: _board.paintBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AthleonMark(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LogoPage())),
          ),
          Text(
            RoomSync.instance.code ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 4),
          ),
          if (widget.event == PistolEvent.pistol)
            const SizedBox(width: 48)
          else
            IconButton(
              tooltip: 'Settings',
              onPressed: () => setState(() {
                _draft = List.of(_saved);
                _settings = !_settings;
              }),
              icon: const Icon(Icons.close, size: 40, color: BoardColors.black54),
            ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SettingsCard(
        title: 'SETTINGS',
        child: Column(
          children: [
            for (var i = 0; i < _specs.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_specs[i].label}  ${_draft[i]}s',
                      style: const TextStyle(color: BoardColors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
              Slider(
                min: _specs[i].min.toDouble(),
                max: _specs[i].max.toDouble(),
                divisions: _specs[i].max - _specs[i].min,
                value: _draft[i].toDouble().clamp(_specs[i].min.toDouble(), _specs[i].max.toDouble()),
                activeColor: BoardColors.green,
                inactiveColor: Colors.white24,
                label: '${_draft[i]}',
                onChanged: (value) => setState(() => _draft[i] = value.round()),
              ),
            ],
            const SizedBox(height: 8),
            CloseSaveRow(onClose: _closeSettings, onSave: _saveSettings),
          ],
        ),
      ),
    );
  }
}
