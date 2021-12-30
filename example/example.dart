import 'dart:async';

import 'package:ensure_initialized/ensure_initialized.dart';

Future main(List<String> args) async {
  print('=== W/O Result ===');
  print('');
  // Resolve it from a DI or so
  final heavyInitialComputations = HeavyInitialComputations();

  try {
    print('Calling doSomething ...');

    final data = await heavyInitialComputations.doSomething();

    print('doSomething result: $data');
  } on Exception catch (e, s) {
    print('Unable to do something');
    print(e);
    print(s);
  }

  print('');
  print('=== W/ Result ===');
  print('');

  // Resolve it from a DI or so
  final heavyInitialComputationsResult = HeavyInitialComputationsResult();

  try {
    print('Calling doSomething ...');

    final data = await heavyInitialComputationsResult.doSomething();

    print('doSomething result: $data');
  } on Exception catch (e, s) {
    print('Unable to do something');
    print(e);
    print(s);
  }
}

class HeavyInitialComputations with EnsureInitialized {
  HeavyInitialComputations() {
    // Call initialization method in constructor,
    // or make it public and call it during creation in the DI.
    _init();
  }

  Future<void> _heavyComputations() async {
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> _init() async {
    try {
      await _heavyComputations();

      initializedSuccessfully();
    } on Exception catch (e, s) {
      initializedWithError(error: e, stackTrace: s);
    }
  }

  /// This method waits for the object to be initialized before doing its stuff.
  Future<int> doSomething() async {
    await ensureInitialized;

    return 25;
  }
}

class HeavyInitialComputationsResult with EnsureInitializedResult<String> {
  HeavyInitialComputationsResult() {
    // Call initialization method in constructor,
    // or make it public and call it during creation in the DI.
    _init();
  }

  Future<String> _heavyComputations() async {
    await Future.delayed(const Duration(seconds: 3));

    return 'I am initialized!';
  }

  Future<void> _init() async {
    try {
      final result = await _heavyComputations();

      initializedSuccessfully(result);
    } on Exception catch (e, s) {
      initializedWithError(error: e, stackTrace: s);
    }
  }

  /// This method waits for the object to be initialized before doing its stuff.
  Future<String> doSomething() async {
    final initResult = await ensureInitialized;

    return initResult.toUpperCase();
  }
}
