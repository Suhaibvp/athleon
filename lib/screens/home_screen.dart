import 'package:flutter/material.dart';

import '../fullscreen.dart';
import '../services/room_sync.dart';
import '../widgets/board_widgets.dart';
import 'air_final_screen.dart';
import 'client_screen.dart';
import 'finals_screen.dart';
import 'pistol25_screen.dart';
import 'rapid_phase_screen.dart';
import 'rifle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _ensureCode();
  }

  Future<void> _ensureCode() async {
    if (RoomSync.instance.code == null) await RoomSync.instance.create();
    if (mounted) setState(() {});
  }

  void _open(Widget screen) {
    Navigator.of(context).push(slidePage(screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            child: Row(
              children: [
                Image.asset('assets/logo.png', width: 36, height: 36),
                const SizedBox(width: 6),
                const Text('ATHLEON', style: TextStyle(fontFamily: 'EurostileExtendedBlack', fontSize: 28)),
                const Spacer(),
                Text(
                  RoomSync.instance.code ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3),
                ),
                TextButton(
                  onPressed: () => _open(const ClientJoinScreen()),
                  child: const Text('CLIENT'),
                ),
                IconButton(
                  tooltip: _fullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
                  onPressed: () {
                    if (_fullscreen) {
                      exitFullscreen();
                    } else {
                      enterFullscreen();
                    }
                    setState(() => _fullscreen = !_fullscreen);
                  },
                  icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 30),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _tile('25M RAPID FIRE PISTOL', const RapidPhaseScreen())),
                        Expanded(child: _tile('10M AIR RIFLE MEN & WOMEN', const RifleScreen())),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _tile('ISSF 3P FINALS', const FinalsScreen())),
                        Expanded(child: _tile('10M FINAL', const AirFinalScreen())),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tile(
                      '25M PISTOL',
                      const Pistol25Screen(),
                      subtitle: 'PISTOL    |    RAPID FIRE PISTOL    |    STANDARD PISTOL',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, Widget screen, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: const Color(0xE6000000),
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(screen),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
