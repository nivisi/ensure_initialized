import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:test/test.dart';

void main() {
  test('toString must return the correct string', () {
    const message = 'This is an error';

    final ex = EnsureInitializedException(message);

    expect(ex.toString(), equals('EnsureInitializedException: $message'));
  });
}
