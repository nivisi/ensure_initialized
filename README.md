# ensure_initialized [![pub version][pub-version-img]][pub-version-url]

[![⚙️ CI][ci-badge-url]][ci-url]

[![CodeFactor][code-factor--badge-url]][code-factor-app-url] 

Sometimes objects can perform heavy initializations that take time. It is nice to have an option to await until the object is ready to use.

### Usage

To make your object "ensure-initializable", add the `EnsureInitialized` mixin:

```dart
class YourObject with EnsureInitialized {
  /* Body */
}
```

Do heavy work in some init method. After it is done, call `initializedSuccessfully`:

```dart
Future<void> init() async {
  await Future.delayed(const Duration(seconds: 3));
  
  initializedSuccessfully();
}
```

Or, if there was an error, call `initializedWithError`:

```dart
Future<void> init() async {
 try {
    await _heavyComputations();

    initializedSuccessfully();
  } on Exception catch (e, s) {
    initializedWithError(error: e, stackTrace: s);
    // Or use message property:
    // initializedWithError(message: 'Something went wrong ...', stackTrace: s);
  }
}
```

Calling the `init` method (or any method that initializes your object) can be done either in a constructor, when registering the object in the DI or anywhere else it has to be initialized. Like so:

```dart
final yourObject = YourObject();

yourObject.init(); // without awaiting, so the DI will be ready to provide users with your object.

DI.register<YourObject>(yourObject);
```

Then, in code, ensure your object is initialized before using it:

```
final yourObject = DI.resolve<YourObject>();

await yourObject.ensureInitialized;

yourObject.doSomeStuff();
```

### In-Code Example

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

### In-Code Example with a Result

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
[pub-version-img]: https://img.shields.io/badge/pub-v0.0.3-green
[pub-version-url]: https://pub.dev/packages/ensure_initialized

[code-factor--badge-url]: https://www.codefactor.io/repository/github/nivisi/ensure_initialized/badge
[code-factor-app-url]: https://www.codefactor.io/repository/github/nivisi/ensure_initialized

[ci-badge-url]: https://github.com/nivisi/ensure_initialized/actions/workflows/ci.yml/badge.svg
[ci-url]: https://github.com/nivisi/ensure_initialized/actions/workflows/ci.yml
