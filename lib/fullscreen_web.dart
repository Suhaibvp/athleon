import 'package:web/web.dart' as web;

void enterFullscreen() {
  web.document.documentElement?.requestFullscreen();
}

void exitFullscreen() {
  web.document.exitFullscreen();
}
