import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:test/test.dart';

import 'result/result_tests.dart' as result;
import 'standard/standard_tests.dart' as standard;

void main() {
  /// EnsureInitializedException tests:

  test('toString must return the correct string', () {
    const message = 'This is an error';

    final ex = EnsureInitializedException(message);

    expect(ex.toString(), equals('EnsureInitializedException: $message'));
  });

  /// EnsureInitializedResultMixin tests:

  result.test_objectInstantiation();
  result.test_initializedSuccessfully();
  result.test_initializedWithError();
  result.test_markAsUninitialized();
  result.test_reinitialize();

  /// EnsureInitializedMixin tests:

  standard.test_objectInstantiation();
  standard.test_initializedSuccessfully();
  standard.test_initializedWithError();
  standard.test_markAsUninitialized();
  standard.test_reinitialize();
}
