import 'dart:async';

import 'package:meta/meta.dart';

import 'ensure_initialized_exception.dart';

/// A mixin that allows to track whether the object is ready for usage.
///
/// Sometimes it is nice to wait for some heavy initialization process before using the object.
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

  /// The method that marks the object has been initialized successfully.
  @protected
  void initializedSuccessfully() {
    if (isInitialized) {
      throw EnsureInitializedException('Object was already initialized');
    }

    _completer.complete();
  }

  /// The method that marks the object was initialized with an error.
  @protected
  void initializedWithError({
    Object? error,
    String? message,
    StackTrace? stackTrace,
  }) {
    assert(
      error != null && message == null || error == null && message != null,
      'You must provide either an error or a message',
    );

    if (_completer.isCompleted) {
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

  @protected
  void markAsUninitialized() {
    if (!isInitialized) {
      throw EnsureInitializedException('Object was not initialized yet');
    }

    _completer = Completer();
  }

  @protected
  Future reinitialize(
    Future Function() future, [
    bool callInitializedWithErrorOnException = true,
  ]) async {
    if (isInitialized) {
      throw EnsureInitializedException('Object was not initialized yet');
    }

    try {
      await future();

      initializedSuccessfully();
    } catch (e, s) {
      if (callInitializedWithErrorOnError) {
      if (callInitializedWithErrorOnException) {
        initializedWithError(error: e, stackTrace: s);
      }

      rethrow;
    }
  }
}
