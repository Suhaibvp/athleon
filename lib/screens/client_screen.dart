import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../board.dart';
import '../widgets/board_widgets.dart';
import 'home_screen.dart';

class ClientJoinScreen extends StatefulWidget {
  const ClientJoinScreen({super.key});

  @override
  State<ClientJoinScreen> createState() => _ClientJoinScreenState();
}

class _ClientJoinScreenState extends State<ClientJoinScreen> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _open() {
    final value = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return;
    Navigator.of(context).push(slidePage(ClientView(code: value)));
  }

  @override
  Widget build(BuildContext context) {
    final ready = RegExp(r'^\d{6}$').hasMatch(_code.text.trim());
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/athleonLOGO.png', width: 80, height: 80, fit: BoxFit.contain),
                const SizedBox(height: 8),
                const Text(
                  'ATHLEON',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _code,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(hintText: '000000', counterText: ''),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _open(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: ready ? _open : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoardColors.tile,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: Colors.black,
                    minimumSize: const Size(220, 52),
                  ),
                  child: const Text('OPEN'),
                ),
              ],
            ),
          ),
        ),
          ),
          Positioned(
            top: 8,
            right: 4,
            child: IconButton(
              tooltip: 'Exit',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 32, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class ClientView extends StatefulWidget {
  const ClientView({super.key, required this.code});

  final String code;

  @override
  State<ClientView> createState() => _ClientViewState();
}

class _ClientViewState extends State<ClientView> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Map<String, dynamic>? _data;
  String? _error;
  Timer? _blink;
  bool _green = true;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance.collection('displayRooms').doc(widget.code).snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _data = snapshot.data();
          _error = null;
        });
        _syncBlink();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _error = 'This number could not be opened.');
      },
    );
  }

  bool get _shouldBlink {
    final data = _data;
    if (data == null) return false;
    final blink = data['blink'] as String? ?? 'none';
    final rawSeconds = data['seconds'];
    final seconds = rawSeconds is num ? rawSeconds.toInt() : null;
    return blink != 'none' && seconds != null && seconds <= 30 && seconds > 0;
  }

  void _syncBlink() {
    if (_shouldBlink && _blink == null) {
      _green = true;
      _blink = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (!mounted) return;
        setState(() => _green = !_green);
      });
    } else if (!_shouldBlink) {
      _blink?.cancel();
      _blink = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _blink?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final text = data?['text'] as String? ?? '';
    final rawSeconds = data?['seconds'];
    final seconds = rawSeconds is num ? rawSeconds.toInt() : null;
    final showLogo = data == null || (text.isEmpty && seconds == null);
    var color = BoardColors.fromName(data?['bg'] as String? ?? 'white');
    if (_shouldBlink) {
      final kind = data?['blink'] as String? ?? 'none';
      if (kind == 'changeOver') {
        color = _green ? BoardColors.green : BoardColors.red;
      } else {
        color = _green ? BoardColors.green : BoardColors.white;
      }
    }
    return Scaffold(
      backgroundColor: color,
      body: Column(
        children: [
          BoardHeader(
            showBrand: false,
            code: widget.code,
            onClose: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(slidePage(const HomeScreen()));
              }
            },
          ),
          Expanded(
            child: Center(
              child: _error != null
                  ? Text(_error!, style: const TextStyle(fontSize: 24))
                  : showLogo
                  ? Image.asset('assets/logo_inactive.jpeg', fit: BoxFit.contain)
                  : CueText(text: text, seconds: seconds),
            ),
          ),
        ],
      ),
    );
  }
}
