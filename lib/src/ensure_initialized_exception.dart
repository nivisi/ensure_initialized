class EnsureInitializedException implements Exception {
  final String message;

  const EnsureInitializedException(this.message);

  @override
  String toString() {
    return 'EnsureInitializedException: $message';
  }
}
