import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../board.dart';
import '../services/room_sync.dart';

class BoardHeader extends StatelessWidget {
  const BoardHeader({
    super.key,
    this.onBack,
    this.onClose,
    this.trailing,
    this.showBrand = true,
    this.code,
  });

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;
  final bool showBrand;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final room = code ?? RoomSync.instance.code ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            ),
          if (showBrand) ...[
            Image.asset('assets/logo.png', width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 4),
            const Text(
              'ATHLEON',
              style: TextStyle(fontFamily: 'EurostileExtendedBlack', fontSize: 28, color: Colors.black),
            ),
          ],
          const Spacer(),
          Text(room, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 3)),
          if (trailing != null) trailing!,
          if (onClose != null)
            IconButton(
              tooltip: 'Exit',
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.black, size: 30),
            ),
        ],
      ),
    );
  }
}

class AthleonMark extends StatelessWidget {
  const AthleonMark({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/athleonLOGO.png', width: 80, height: 80, fit: BoxFit.contain),
        const SizedBox(width: 8),
        const Text(
          'ATHLEON',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
    if (onTap == null) return mark;
    return InkWell(onTap: onTap, child: mark);
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: BoardColors.tile,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xE6000000),
            disabledForegroundColor: const Color(0x80FFFFFF),
            disabledBackgroundColor: const Color(0x80000000),
            minimumSize: const Size(100, 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, textAlign: TextAlign.center, maxLines: 4),
        ),
    );
    if (!expand) return button;
    return Expanded(child: button);
  }
}

Route<void> slidePage(Widget page) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

class CueText extends StatefulWidget {
  const CueText({super.key, this.text, this.seconds});

  final String? text;
  final int? seconds;

  @override
  State<CueText> createState() => _CueTextState();
}

class _CueTextState extends State<CueText> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previous,
            if (current != null) current,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: _CueBody(key: ValueKey<String>(widget.text ?? ''), text: widget.text, seconds: widget.seconds),
    );
  }
}

class _CueBody extends StatelessWidget {
  const _CueBody({super.key, this.text, this.seconds});

  final String? text;
  final int? seconds;

  @override
  Widget build(BuildContext context) {
    final line = text;
    final time = seconds;
    if ((line == null || line.isEmpty) && time == null) return const SizedBox.shrink();
    final children = <Widget>[];
    if (line != null && line.isNotEmpty) {
      children.add(
        Text(
          line,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: time == null ? 100 : 100,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      );
    }
    if (time != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 20));
      children.add(
        Text(
          formatClock(time),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: line == null || line.isEmpty ? 250 : 150,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class ClockField extends StatelessWidget {
  const ClockField({super.key, required this.controller, this.width = 50, this.fontSize = 16});

  final TextEditingController controller;
  final double width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        style: TextStyle(color: BoardColors.green, fontSize: fontSize, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '00',
          hintStyle: TextStyle(color: BoardColors.green),
          isDense: true,
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: BoardColors.green, width: 2)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: BoardColors.green, width: 2)),
        ),
      ),
    );
  }
}

class TimePair extends StatelessWidget {
  const TimePair({
    super.key,
    required this.label,
    required this.minutes,
    required this.seconds,
    this.fieldWidth = 50,
    this.fontSize = 16,
  });

  final String label;
  final TextEditingController minutes;
  final TextEditingController seconds;
  final double fieldWidth;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: BoardColors.green, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClockField(controller: minutes, width: fieldWidth, fontSize: fontSize),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(color: BoardColors.green, fontSize: fontSize)),
            ),
            ClockField(controller: seconds, width: fieldWidth, fontSize: fontSize),
          ],
        ),
      ],
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.child, this.width = 400});

  final String title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: BoardColors.green, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CloseSaveRow extends StatelessWidget {
  const CloseSaveRow({super.key, required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              minimumSize: const Size(0, 44),
            ),
            child: const Text('CLOSE'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: BoardColors.green,
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('SAVE'),
          ),
        ),
      ],
    );
  }
}
