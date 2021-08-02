# ensure_initialized

[![pub version][pub-version-img]][pub-version-url]

Sometimes objects can perform heavy initializations that take time. It is nice to have an option to await until the object is ready to use.

### Simple usage

```dart
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

  Future<int> doSomething() async {
    await ensureInitialized;

    return 25;
  }
}

Future main(List<String> args) async {
  // Resolve it from a DI or so
  final heavyInitialComputations = HeavyInitialComputations();

  try {
    final data = await heavyInitialComputations.doSomething();

    print(data);
  } on Exception catch (e, s) {
    print('Unable to do something');
    print(e);
    print(s);
  }
}
```

### Simple usage with result

Yep, sometimes it makes sense to retrieve a result from those heavy initialization steps. To do so, you can use `EnsureInitializedResult`:
```dart
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

  Future<String> doSomething() async {
    final initResult = await ensureInitialized;

    return initResult.toUpperCase();
  }
}

Future main(List<String> args) async {
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
```

<!-- References -->
[pub-version-img]: https://img.shields.io/badge/pub-v0.0.1-green
[pub-version-url]: https://pub.dev/packages/ensure_initialized
