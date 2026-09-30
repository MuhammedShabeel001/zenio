/// Runs asynchronous tasks one at a time, in the order they were added.
///
/// Notifiers that persist a whole list (read, modify, write) use this so two
/// quick edits cannot both start from the same list and overwrite each other.
class SerialTaskQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    // Keep the chain alive even when a task fails; the caller still receives
    // the error through [result].
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
