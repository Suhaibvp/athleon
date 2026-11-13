import 'package:flutter_test/flutter_test.dart';

import 'package:athleon_v3/board.dart';

void main() {
  test('clock format matches the range board', () {
    expect(formatClock(50), '0:50');
    expect(formatClock(90), '1:30');
    expect(parseClock('1:05'), 65);
  });
}
