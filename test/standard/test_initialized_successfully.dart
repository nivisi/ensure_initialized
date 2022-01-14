import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import 'src/result_initializable_object.dart';

void test_initializedSuccessfully() {
  group('when initializedSuccessfully is called', () {
    group('and object was already initialized', () {
      test('must throw an EnsureInitializedError', () {
        final object = InitializableObject();

        object.initializedSuccessfully();

        expect(
          () => object.initializedSuccessfully(),
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
        final object = InitializableObject();
        object.initializedSuccessfully();
        try {
          object.initializedSuccessfully();
        } catch (e) {
          // Catch it to prevent test from failing
        }

        expect(object.isInitialized, isTrue);
      });
    });

    group('and object was not initialized yet', () {
      test(
        'whenInitialized must emit an eventt',
        () async {
          final object = InitializableObject();

          expectLater(object.whenInitialized, emits(null));

          object.initializedSuccessfully();
        },
      );

      test(
        'isInitialized must be set to true',
        () async {
          final object = InitializableObject();
          object.initializedSuccessfully();

          expect(object.isInitialized, isTrue);
        },
      );

      test(
        'ensureInitialized must return the given result',
        () async {
          final object = InitializableObject();
          object.initializedSuccessfully();

          expect(object.ensureInitialized, completes);
        },
      );
    });
  });
}
