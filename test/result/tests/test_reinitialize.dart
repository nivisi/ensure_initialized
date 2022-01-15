import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import '../src/result_initializable_object.dart';

void test_reinitialize() {
  group('when reinitialize is called', () {
    group('and object was not initialized yet', () {
      test('must throw an EnsureInitializedException', () {
        final object = ResultInitializableObject();

        expect(
          () => object.reinitialize(() async => 0),
          throwsA(
            isA<EnsureInitializedException>().having(
              (e) => e.message,
              'message',
              wasNotInitializedYetMessage,
            ),
          ),
        );
      });
    });

    group('and object was already initialized', () {
      group('and reinitialization function completes normally', () {
        test('streams must emit events in order', () {
          const whenUninitialized = 'whenUninitialized';
          const whenInitialized = 'whenInitialized';
          final expectedReinitResult = 5;

          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          final emitted = <String>[];

          expectLater(
            object.whenUninitialized,
            emits(predicate((event) {
              if (emitted.contains(whenInitialized)) {
                // Meaning that whenUninitialized was fired second
                return false;
              }
              emitted.add(whenUninitialized);
              return true;
            })),
          );
          expectLater(
            object.whenInitialized,
            emits(predicate((event) {
              if (!emitted.contains(whenUninitialized)) {
                // Meaning that whenInitialized was fired first
                return false;
              }

              emitted.add(whenInitialized);
              return event == expectedReinitResult;
            })),
          );

          object.reinitialize(() async => expectedReinitResult);
        });

        test('whenUninitialized must emit an event with the given result', () {
          final expectedReinitResult = 5;

          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          expectLater(object.whenUninitialized, emits(null));

          object.reinitialize(() async => expectedReinitResult);
        });

        test('whenInitialized must emit an event', () {
          final expectedReinitResult = 5;

          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          expectLater(object.whenInitialized, emits(expectedReinitResult));

          object.reinitialize(() async => expectedReinitResult);
        });

        test('ensureInitialized must return the given result', () async {
          const expectedResult = 10;

          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          object.reinitialize(
            () async => expectedResult,
            callInitializedWithErrorOnException: true,
          );

          final actualResult = await object.ensureInitialized;

          expect(actualResult, equals(expectedResult));
        });

        test('isInitialized must be true', () async {
          final object = ResultInitializableObject();
          object.initializedSuccessfully(0);

          await object.reinitialize(
            () async => 5,
            callInitializedWithErrorOnException: true,
          );

          expect(object.isInitialized, isTrue);
        });
      });

      group('and reinitialization function throws an error', () {
        group('and callInitializedWithErrorOnException is true', () {
          test('the call must throw the given Exception', () async {
            const exception = FormatException();

            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            expect(
              () => object.reinitialize(
                () {
                  throw exception;
                },
                callInitializedWithErrorOnException: true,
              ),
              throwsA(predicate((e) => e == exception)),
            );

            // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
            await object.ensureInitialized.catchError((_) async => 0);
          });

          test('streams must emit events in order', () async {
            const whenUninitialized = 'whenUninitialized';
            const whenInitialized = 'whenInitialized';
            const exception = FormatException();

            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            final emitted = <String>[];

            expectLater(
              object.whenUninitialized,
              emits(predicate((event) {
                if (emitted.contains(whenInitialized)) {
                  // Meaning that whenUninitialized was fired second
                  return false;
                }
                emitted.add(whenUninitialized);
                return true;
              })),
            );
            expectLater(
              object.whenInitialized,
              emitsError(predicate((event) {
                if (!emitted.contains(whenUninitialized)) {
                  // Meaning that whenInitialized was fired first
                  return false;
                }

                emitted.add(whenInitialized);
                return event == exception;
              })),
            );

            try {
              await object.reinitialize(
                () async => throw exception,
                callInitializedWithErrorOnException: true,
              );
            } catch (_) {
              // Catch it to prevent the test from failing
            }

            // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
            await object.ensureInitialized.catchError((_) async => 0);
          });

          test('whenUninitialized must emit an event', () {
            final expectedReinitResult = 5;

            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            expectLater(object.whenUninitialized, emits(null));

            object.reinitialize(
              () async => expectedReinitResult,
              callInitializedWithErrorOnException: true,
            );
          });

          test(
            'whenInitialized must emit the given error',
            () async {
              const exception = FormatException();

              final object = ResultInitializableObject();
              object.initializedSuccessfully(0);

              expectLater(object.whenInitialized, emitsError(exception));

              try {
                await object.reinitialize(
                  () async => throw exception,
                  callInitializedWithErrorOnException: true,
                );
              } catch (_) {
                // Catch it to prevent the test from failing
              }

              // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
              await object.ensureInitialized.catchError((_) async => 0);
            },
          );

          test('ensureInitialized must throw the given Exception', () async {
            const exception = FormatException();

            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            try {
              await object.reinitialize(
                () async => throw exception,
                callInitializedWithErrorOnException: true,
              );
            } catch (_) {
              // Catch it to prevent the test from failing
            }

            expect(
              () => object.ensureInitialized,
              throwsA(predicate((e) => e == exception)),
            );
          });

          test('isInitialized must be true', () async {
            const exception = FormatException();

            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            try {
              await object.reinitialize(
                () async => throw exception,
                callInitializedWithErrorOnException: true,
              );
            } catch (_) {
              // Catch it to prevent the test from failing
            }

            expect(object.isInitialized, isTrue);

            // See https://stackoverflow.com/questions/66479535/exception-thrown-when-calling-completer-completeerror
            await object.ensureInitialized.catchError((_) async => 0);
          });
        });

        group('and callInitializedWithErrorOnException is false', () {
          test(
            'whenInitialized must emit an event only after being initialized',
            () async {
              const laterInitializationResult = 1912;

              final object = ResultInitializableObject();
              object.initializedSuccessfully(0);

              try {
                await object.reinitialize(
                  () async => throw Exception(),
                  callInitializedWithErrorOnException: false,
                );
              } catch (_) {
                // Catch it to prevent the test from failing
              }

              await Future.delayed(const Duration(seconds: 1));

              expect(object.whenInitialized, emits(laterInitializationResult));
              object.initializedSuccessfully(laterInitializationResult);
            },
          );

          test(
            'ensureInitialized does not complete',
            () async {
              final object = ResultInitializableObject();
              object.initializedSuccessfully(0);

              try {
                await object.reinitialize(
                  () => throw Exception(),
                  callInitializedWithErrorOnException: false,
                );
              } catch (_) {
                // Catch it to prevent the test from failing
              }

              expect(object.ensureInitialized, doesNotComplete);
            },
          );

          test('isInitialized must be false', () async {
            final object = ResultInitializableObject();
            object.initializedSuccessfully(0);

            try {
              await object.reinitialize(
                () => throw Exception(),
                callInitializedWithErrorOnException: false,
              );
            } catch (_) {
              // Catch it to prevent the test from failing
            }

            expect(object.isInitialized, isFalse);
          });
        });
      });
    });
  });
}
