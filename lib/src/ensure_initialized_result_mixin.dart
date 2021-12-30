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
/// class SomeClass with EnsureInitializedResultMixin<int> {
///   SomeClass() {
///     _init();
///   }
///
///   Future<int> _heavyComputations() async {
///     await Future.delayed(const Duration(seconds: 5));
///
///     return 0;
///   }
///
///   Future<void> _init() async {
///     try {
///       final result = await _heavyComputations();
///
///       initializedSuccessfully(result);
///     } on Exception catch (e, s) {
///       initializedWithError(error: e, stackTrace: s);
///     }
///   }
/// }
/// ```
mixin EnsureInitializedResultMixin<T> {
  Completer<T> _completer = Completer<T>();

  final StreamController<T> _whenInitializedStreamController =
      StreamController<T>.broadcast();
  final StreamController<void> _whenUninitializedStreamController =
      StreamController<void>.broadcast();

  /// Released when [initializedSuccessfully] is called.
  /// Returns the result of initialization.
  /// If [initializedWithError] is called, throws the given exception.
  Future<T> get ensureInitialized => _completer.future;

  /// Fired when [initializedSuccessfully] is called.
  /// The event would be the result of initialization.
  /// If [initializedWithError] is called, the given exception is passed to the
  /// `onError` callback.
  Stream<T> get whenInitialized => _whenInitializedStreamController.stream;

  /// Fired when [markAsUninitialized] is called.
  ///
  /// Note that it will also be fired during the [reinitialize] method
  /// as it executes [markAsUninitialized].
  Stream<void> get whenUninitialized =>
      _whenUninitializedStreamController.stream;

  /// Simply checks if the object is initialized at the moment.
  bool get isInitialized => _completer.isCompleted;

  /// Marks that the object has been initialized successfully.
  ///
  /// [result] is a value that is returned by the [ensureInitialized] future.
  ///
  /// Throws:
  /// - [EnsureInitializedException] if object was already initialized.
  @protected
  void initializedSuccessfully(T result) {
    if (isInitialized) {
      throw EnsureInitializedException('Object was already initialized');
    }

    _completer.complete(result);
    _whenInitializedStreamController.add(result);
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
      final exception = EnsureInitializedException(message!);

      _completer.completeError(
        exception,
        stackTrace,
      );
      _whenInitializedStreamController.addError(exception);
    } else {
      _completer.completeError(
        error,
        stackTrace,
      );
      _whenInitializedStreamController.addError(error);
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

    _completer = Completer<T>();
    _whenUninitializedStreamController.add(null);
  }

  /// Allows to reinitialize the object with the call of the given future.
  ///
  /// - [future] is a future to execute during reinitialization.
  ///
  ///   Before executing it, the object will be marked as not initialized.
  ///   The result of the [future] will be set as the result of initialization
  ///   (by calling `initializedSuccessfully(result)`).
  ///
  ///    If [future] throws an exception, it will be rethrown to the caller.
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
    Future<T> Function() future, {
    bool callInitializedWithErrorOnException = true,
  }) async {
    if (!isInitialized) {
      throw EnsureInitializedException('Object was not initialized yet');
    }

    markAsUninitialized();

    try {
      final result = await future();

      initializedSuccessfully(result);
    } on Exception catch (e, s) {
      if (callInitializedWithErrorOnException) {
        initializedWithError(error: e, stackTrace: s);
      }

      rethrow;
    }
  }
}
