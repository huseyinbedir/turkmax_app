import 'dart:async';

/// Son değeri yeni abonelere hemen ileten küçük yayıncı.
class StateBroadcaster<T> {
  StateBroadcaster(this._value);

  final _controller = StreamController<T>.broadcast();
  T _value;

  T get value => _value;

  void emit(T value) {
    _value = value;
    _controller.add(value);
  }

  Stream<T> get stream => Stream<T>.multi((listener) {
    listener.add(_value);
    final subscription = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
    );
    listener.onCancel = subscription.cancel;
  });
}
