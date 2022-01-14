import 'package:test/test.dart';

import '../src/result_initializable_object.dart';

void test_objectInstantiation() {
  group('when object is instantiated,', () {
    test('isInitialized must be false', () {
      final object = ResultInitializableObject();

      expect(object.isInitialized, isFalse);
    });
    test('ensureInitialized must not complete', () {
      final object = ResultInitializableObject();

      expect(object.ensureInitialized, doesNotComplete);
    });
  });
}
