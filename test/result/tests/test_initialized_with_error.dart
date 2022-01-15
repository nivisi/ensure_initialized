import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import '../src/result_initializable_object.dart';

void test_initializedWithError() {
  group('when initializedWithError is called', () {
    group('and object was already initialized', () {
      test('must throw an EnsureInitializedError', () {
        final object = ResultInitializableObject();

        object.initializedSuccessfully(0);

        expect(
          () => object.initializedWithError(message: 'messsage'),
          throwsA(
            isA<EnsureInitializedException>().having(
              (e) => e.message,
              'message',
              alreadyInitializedMessage,
            ),
          ),
        );
      });

      test(
        'isInitialized must remain true',
        () async {
          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          try {
            object.initializedWithError(message: '');
          } catch (_) {
            // Catch it to prevent test from failing
          }

          expect(object.isInitialized, isTrue);
        },
      );
    });

    group('and object was not initialized yet', () {
      group('and error was created with a message', () {
        test('isInitialized must remain true', () async {
          const errorMessage = 'Initialization went wrong';

          final object = ResultInitializableObject();
          object.initializedWithError(message: errorMessage);

          expect(object.isInitialized, isTrue);

          // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
          await object.ensureInitialized.catchError((_) async => 0);
        });

        test('whenInitialized must emit an error', () async {
          const errorMessage = 'Initialization went wrong';

          final object = ResultInitializableObject();

          expectLater(
              object.whenInitialized,
              emitsError(
                isA<EnsureInitializedException>().having(
                  (e) => e.message,
                  'message',
                  errorMessage,
                ),
              ));

          object.initializedWithError(message: errorMessage);

          // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
          await object.ensureInitialized.catchError((_) async => 0);
        });

        test(
          'ensureInitialized must throw an EnsureInitializedException with the given message',
          () {
            const errorMessage = 'Initialization went wrong';

            final object = ResultInitializableObject();
            object.initializedWithError(message: errorMessage);

            expect(
              () => object.ensureInitialized,
              throwsA(
                isA<EnsureInitializedException>().having(
                  (e) => e.message,
                  'message',
                  errorMessage,
                ),
              ),
            );
          },
        );
      });

      group('and error was created with another error', () {
        test('isInitialized must be true', () async {
          const exception = FormatException();

          final object = ResultInitializableObject();
          object.initializedWithError(error: exception);

          expect(object.isInitialized, isTrue);

          // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
          await object.ensureInitialized.catchError((_) async => 0);
        });

        test('whenInitialized must emit the given error', () async {
          const exception = FormatException();

          final object = ResultInitializableObject();

          expectLater(
            object.whenInitialized,
            emitsError(predicate((e) => e == exception)),
          );

          object.initializedWithError(error: exception);

          // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
          await object.ensureInitialized.catchError((_) async => 0);
        });

        test('ensureInitialized must throw the given error', () {
          const exception = FormatException('Something went wrong!');

          final object = ResultInitializableObject();
          object.initializedWithError(error: exception);

          expect(
            () => object.ensureInitialized,
            throwsA(predicate((e) => e == exception)),
          );
        });
      });
    });

    group('and both message and error are passed', () {
      test('must throw an AssertionError', () {
        final object = ResultInitializableObject();

        expect(
          () => object.initializedWithError(
            error: 'error',
            message: 'messsage',
          ),
          throwsA(isA<AssertionError>().having(
            (e) => e.message,
            'message',
            mustProvideEitherMessageOrErrorMessage,
          )),
        );
      });
    });

    group('and both message and error are not passed', () {
      test('must throw an EnsureInitializedException', () {
        final object = ResultInitializableObject();

        expect(
          () => object.initializedWithError(message: null, error: null),
          throwsA(isA<EnsureInitializedException>().having(
            (e) => e.message,
            'message',
            mustProvideEitherMessageOrErrorMessage,
          )),
        );
      });
    });
  });
}
