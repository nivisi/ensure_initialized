import 'dart:async';

import 'package:meta/meta.dart';

import 'ensure_initialized_exception.dart';

/// Allows to track whether the object is ready for usage.
///
/// Sometimes it is nice to wait for some heavy initialization process before using an object.
/// Instead of implementing some kind of booleans, we can use futures instead.
///
/// Example:
/// ```dart
/// class SomeClass with EnsureInitialized {
///   SomeClass() {
///     _init();
///   }
///
///   Future<void> _heavyComputations() async {
///     await Future.delayed(const Duration(seconds: 5));
///   }
///
///   Future<void> _init() async {
///     try {
///       await _heavyComputations();
///
///       initializedSuccessfully();
///     } on Exception catch (e, s) {
///       unableToInitialize(e, s);
///     }
///   }
/// }
/// ```
mixin EnsureInitialized {
  Completer<void> _completer = Completer<void>();

  Future<void> get ensureInitialized => _completer.future;

  bool get isInitialized => _completer.isCompleted;

  /// Marks that the object has been initialized successfully.
  ///
  /// Throws:
  /// - [EnsureInitializedException] if object was already initialized.
  @protected
  void initializedSuccessfully() {
    if (isInitialized) {
      throw EnsureInitializedException('Object was already initialized');
    }

    _completer.complete();
  }

  /// Marks that the object was initialized with an error.
  ///
  /// - If [error] is provided, it will be rethrown by [ensureInitialized].
  /// - If [message] is provided, it will be wrapped in a [EnsureInitializedException]
  /// and this exception will be rethrown by [ensureInitialized].
  /// - If [stackTrace] is provided, it will set as a StackTrace for the error.
  ///
  /// Preferably, provide either an [error] or a [message].
  /// If both of them are not null, [message] will be ignored.
  ///
  /// Throws:
  /// - [EnsureInitializedException] if object was already initialized.
  /// - [EnsureInitializedException] if both [error] and [message] were not provided.
  @protected
  void initializedWithError({
    Object? error,
    String? message,
    StackTrace? stackTrace,
  }) {
    if (error == null && message == null) {
      throw EnsureInitializedException(
        'You must provide either an error or a message',
      );
    }

    assert(
      error != null && message == null || error == null && message != null,
      'You must provide either an error or a message',
    );

    if (isInitialized) {
      throw EnsureInitializedException('Object was already initialized');
    }

    if (error == null) {
      _completer.completeError(
        EnsureInitializedException(message!),
        stackTrace,
      );
    } else {
      _completer.completeError(
        error,
        stackTrace,
      );
    }
  }

  /// Marks that the object is again not initialized. After this, you can call
  /// [initializedSuccessfully] again.
  ///
  /// Throws:
  /// - [EnsureInitializedException] if object was not initialized yet.
  @protected
  void markAsUninitialized() {
    if (!isInitialized) {
      throw EnsureInitializedException('Object was not initialized yet');
    }

    _completer = Completer();
  }

  /// Allows to reinitialize the object with the call of the given future.
  ///
  /// - [future] is a future to execute during reinitialization.
  ///
  ///   Before executing it, the object will be marked as not initialized.
  ///   If [future] throws an exception, it will be rethrown to the caller.
  ///
  /// - [callInitializedWithErrorOnException] indicates whether to call [initializedWithError]
  /// on Exception or not.
  ///
  ///    For example, you can capture the exception, handle it and then
  ///    decide if [initializedWithError] should be called or not.
  ///
  /// Throws:
  /// - [EnsureInitializedException] if object was not initialized yet.
  @protected
  Future reinitialize(
    Future Function() future, {
    bool callInitializedWithErrorOnException = true,
  }) async {
    if (!isInitialized) {
      throw EnsureInitializedException('Object was not initialized yet');
    }

    markAsUninitialized();

    try {
      await future();

      initializedSuccessfully();
    } on Exception catch (e, s) {
      if (callInitializedWithErrorOnException) {
        initializedWithError(error: e, stackTrace: s);
      }

      rethrow;
    }
  }
}
