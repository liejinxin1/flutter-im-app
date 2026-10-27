import 'package:flutter/foundation.dart';

abstract class ViewModel extends ChangeNotifier {
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    // Async operations may finish after their screen has been removed.
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    super.dispose();
  }
}
