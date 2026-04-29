import 'dart:async';

class ShareServiceImpl {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Stream pubblico (sempre vuoto per ora)
  static Stream<String> get linkStream => _controller.stream;

  /// ❌ INIT DISABILITATO TEMPORANEAMENTE
  static void init() {
    // NIENTE MethodChannel
    // NIENTE chiamate native
  }

  static void dispose() {
    _controller.close();
  }
}
