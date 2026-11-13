import 'package:flutter/material.dart';

import '../widgets/board_widgets.dart';
import 'client_screen.dart';
import 'home_screen.dart';
import 'logo_page.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AthleonMark(onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LogoPage()));
            }),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: EventTile(
                    label: 'HOST',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
                    },
                  ),
                ),
                Expanded(
                  child: EventTile(
                    label: 'CLIENT',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClientJoinScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
