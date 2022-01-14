import 'package:ensure_initialized/ensure_initialized.dart';
import 'package:ensure_initialized/src/error_messages/error_messages.dart';
import 'package:test/test.dart';

import 'src/result_initializable_object.dart';

void test_markAsUninitialized() {
  group('when markAsUninitialized is called', () {
    group('and object was not initialized yet', () {
      test('must throw an EnsureInitializedException', () {
        final object = InitializableObject();

        expect(
          () => object.markAsUninitialized(),
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
      test('whenUninitialized must emit an event', () {
        final object = InitializableObject();
        object.initializedSuccessfully();

        expectLater(object.whenUninitialized, emits(null));

        object.markAsUninitialized();
      });

      test('isInitilized must be set to false', () {
        final object = InitializableObject();
        object.initializedSuccessfully();

        object.markAsUninitialized();

        expect(object.isInitialized, isFalse);
      });
    });
  });
}
