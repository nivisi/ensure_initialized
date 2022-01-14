import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import '../src/result_initializable_object.dart';

void test_initializedSuccessfully() {
  group('when initializedSuccessfully is called', () {
    group('and object was already initialized', () {
      test('must throw an EnsureInitializedError', () {
        final object = ResultInitializableObject();

        object.initializedSuccessfully(0);

        expect(
          () => object.initializedSuccessfully(0),
          throwsA(
            isA<EnsureInitializedException>().having(
              (e) => e.message,
              'message',
              alreadyInitializedMessage,
            ),
          ),
        );
      });

      test('isInitilized must remain true', () {
        final object = ResultInitializableObject();
        object.initializedSuccessfully(0);
        try {
          object.initializedSuccessfully(0);
        } catch (e) {
          // Catch it to prevent test from failing
        }

        expect(object.isInitialized, isTrue);
      });
    });

    group('and object was not initialized yet', () {
      test(
        'whenInitialized must emit an event with the given result',
        () async {
          const result = 19;

          final object = ResultInitializableObject();

          expectLater(object.whenInitialized, emits(result));

          object.initializedSuccessfully(result);
        },
      );

      test(
        'isInitialized must be set to true',
        () async {
          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          expect(object.isInitialized, isTrue);
        },
      );

      test(
        'ensureInitialized must return the given result',
        () async {
          const expectedResult = 0;
          final object = ResultInitializableObject();
          object.initializedSuccessfully(expectedResult);

          final actualResult = await object.ensureInitialized;

          expect(actualResult, equals(expectedResult));
        },
      );
    });
  });
}
