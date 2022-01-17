# ensure_initialized [![pub version][pub-version-img]][pub-version-url]

[![⚙️ CI][ci-badge-url]][ci-url] [![CodeFactor][code-factor--badge-url]][code-factor-app-url]  [![codecov][codecov-badge-url]][codecov-url]

Sometimes objects can perform heavy initialization or preparation that take some time. Until that is done, the object could be not ready for usage. This package allows to await for initialization, ensuring the object is ready to use.

## Usage

Add the `EnsureInitializedMixin` mixin to a class:

```dart
class YourObject with EnsureInitializedMixin {
  /* Body */
}
```

Now you can await for your object initialization:

```dart
final object = YourObject();

await object.ensureInitialized;

object.doSomethingAfterItIsReady();
```

If your initialization has some output value, you can use `EnsureInitializedResultMixin<T>`:

```dart
class YourObjectWithResult with EnsureInitializedResultMixin<int> {
  /* Body */
}

final objectWithResult = YourObjectWithResult();

final result = await objectWithResult.ensureInitialized;

print(result);
```

You can also check whether your object was already initialized by reading the `isInitialized` property:

```dart
final object = YourObject();

print(object.isInitialized); // false

await object.init(); // this method calls `initializedSuccessfully` under the hood

print(object.isInitialized); // true
```

### Successful Initialization

`ensureInitialized` will be released after you call either `initializedSuccessfully`. Do it in your heavy initialization method:

```dart
Future<void> init() async {
  await Future.delayed(const Duration(seconds: 3));
  
  initializedSuccessfully();
}
```

If you use `EnsureInitializedResultMixin<T>`, you must pass a value of type `T` to the call:

```dart
initializedSuccessfully(5);
```

This value will be returned by the `ensureInitialized`:

```dart
final result = await objectWithResult.ensureInitialized;
print(result); // prints 5
```

### Failed Initialization

To mark that the object was initialized with an error, call `initializedWithError`. It can take a message, an exception and a stacktrace.

Note: it is preferrable to use either a message or an exception. You'll get an assertion error in debug otherwise. In release the message will be ignored in case both values are specified.

```dart
Future<void> init() async {
  try {
    await Future.delayed(const Duration(seconds: 3));
    
    initializedSuccessfully();
  } on Exception catch (e, s) {
    initializedWithError(error: e, stackTrace: s);
    // Or use message: initializedWithError(message: e.toString(), stackTrace: s);
  }
}
```

So `ensureInitialized` may throw the specified exception. It could be used as following:

```dart
try {
  await object.ensureInitialized;
  
  /* Do the happy path */
} on Exception catch (e ,s) {
  /* Log it and do the unhappy path */
}
```

Note that calling `initializedWithError` also turns `isInitialized` to true.

### Streams

There are `whenInitialized` and `whenUninitialized` streams that will raise an event when the object is initialized and uninitialized (later on about the latter):

```dart
object.whenInitialized.listen((_) {
  print('My object was initialized!');
});
```

It can also be used with the result mixin. Then the event will be the result of initialization:

```dart
objectWithResult.whenInitialized.listen((result) {
  print('My object was initialized with $result!');
});
```

`whenInitialized` is fired any time `initializedSuccessfully` or `initializedWithError` are called. If the object was initialized with an error, this error will be added to the stream as well.

`whenUninitialized` is fired any time the object is marked as uninitialized.

### Reinitialization

Sometimes it is needed to reinit an object. For instance, some service relies on the user service, that relies on what user is currently signed in. You can call `markAsUninitialized` to point that the object is not ready to be used again.

```dart
class UserService with EnsureInitializedMixin {
  Future signIn(credentials) async {
    /* Do sign in */
    
    initializedSuccessfully();
  }
  
  Future signOut() async {
    /* Do sign out */
    
    markAsUninitialized();
  }
}
```

Now, if you call `signOut`, the object will return to its initial state: `isInitialized` will be false and `ensureInitialized` will again be awaitable. It will also fire the `whenUninitialized` event.

So now we can get notified about this in another service:

```dart
class ServiceThatReliesOnUserService with EnsureInitializedMixin {
  final UserService userService;
  
  later final StreamSubscription _onInitializedSubscription;
  later final StreamSubscription _onUninitializedSubscription;
  
  ServiceThatReliesOnUserService(this.userService) {
    _init();
  }
  
  void _init() {
    _onInitializedSubscription = userService.whenInitialized.listen(_whenUserServiceInitialized);
    _onUninitializedSubscription = userService.whenUninitialized.listen(_whenUserServiceUninitialized);
  }
  
  void _whenUserServiceInitialized(_) {
    /* Do something with userService */
    initializedSuccessfully();
  }
  
  void _whenUserServiceUninitialized(_) {
    markAsUninitialized();
  }
  
  void dispose() {
    _onInitializedSubscription.cancel();
    _onUninitializedSubscription.cancel();
  }
}
```

We can build chains with objects that rely on each other. Don'get overwhelmed, though!

Alternatively, you can use a `reinitialize` method that takes a future as a parameter. The object will be marked as uninitialized before the future starts and will be marked as initialized after it completes. 

```dart
Future reinitMe() {
  return reinitialize(() => Future.delayed(const Duration(seconds: 3)));
}
```

Note: if any exception occur, `reinitialize` will rethrow it. It also takes a flag `callInitializedWithErrorOnException` that indicates whether to call `initializedWithError` on exception.

<!-- References -->
[pub-version-img]: https://img.shields.io/badge/pub-v0.1.0-green
[pub-version-url]: https://pub.dev/packages/ensure_initialized

[code-factor--badge-url]: https://www.codefactor.io/repository/github/nivisi/ensure_initialized/badge
[code-factor-app-url]: https://www.codefactor.io/repository/github/nivisi/ensure_initialized

[ci-badge-url]: https://github.com/nivisi/ensure_initialized/actions/workflows/ci.yml/badge.svg
[ci-url]: https://github.com/nivisi/ensure_initialized/actions/workflows/ci.yml

[codecov-badge-url]: https://codecov.io/gh/nivisi/ensure_initialized/branch/develop/graph/badge.svg?token=80NZYCFQH3
[codecov-url]: https://codecov.io/gh/nivisi/ensure_initialized
