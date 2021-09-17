extension ObjectExtensions<T> on T {
  /// Calls the provided [fn] on this object.
  R map<R>(R Function(T) fn) => fn(this);
}
