import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import '../src/result_initializable_object.dart';

void test_reinitialize() {
  group('when reinitialize is called', () {
    group('and object was not initialized yet', () {
      test('must throw an EnsureInitializedException', () {
        final object = InitializableObject();

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

          final object = InitializableObject();
          object.initializedSuccessfully();

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
              return true;
            })),
          );

          object.reinitialize(() async {});
        });

        test('whenUninitialized must emit an event with the given result', () {
          final object = InitializableObject();
          object.initializedSuccessfully();

          expectLater(object.whenUninitialized, emits(null));

          object.reinitialize(() async {});
        });

        test('whenInitialized must emit an event', () {
          final object = InitializableObject();
          object.initializedSuccessfully();

          expectLater(object.whenInitialized, emits(null));

          object.reinitialize(() async {});
        });

        test('ensureInitialized must be completed', () async {
          final object = InitializableObject();
          object.initializedSuccessfully();

          object.reinitialize(
            () async {},
            callInitializedWithErrorOnException: true,
          );

          expect(object.ensureInitialized, completes);
        });

        test('isInitialized must be true', () async {
          final object = InitializableObject();
          object.initializedSuccessfully();

          await object.reinitialize(
            () async {},
            callInitializedWithErrorOnException: true,
          );

          expect(object.isInitialized, isTrue);
        });
      });

      group('and reinitialization function throws an error', () {
        group('and callInitializedWithErrorOnException is true', () {
          test('the call must throw the given Exception', () async {
            const exception = FormatException();

            final object = InitializableObject();
            object.initializedSuccessfully();

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

            final object = InitializableObject();
            object.initializedSuccessfully();

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

            final object = InitializableObject();
            object.initializedSuccessfully();

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

              final object = InitializableObject();
              object.initializedSuccessfully();

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

            final object = InitializableObject();
            object.initializedSuccessfully();

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

            final object = InitializableObject();
            object.initializedSuccessfully();

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
              final object = InitializableObject();
              object.initializedSuccessfully();

              try {
                await object.reinitialize(
                  () async => throw Exception(),
                  callInitializedWithErrorOnException: false,
                );
              } catch (_) {
                // Catch it to prevent the test from failing
              }

              await Future.delayed(const Duration(seconds: 1));

              expect(object.whenInitialized, emits(null));
              object.initializedSuccessfully();
            },
          );

          test(
            'ensureInitialized does not complete',
            () async {
              final object = InitializableObject();
              object.initializedSuccessfully();

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
            final object = InitializableObject();
            object.initializedSuccessfully();

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
