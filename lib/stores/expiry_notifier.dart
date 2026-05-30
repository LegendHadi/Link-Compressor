import 'dart:async';

import 'package:flutter/foundation.dart';

class ExpiryNotifier extends ChangeNotifier {
  Timer? _timer;

  ExpiryNotifier() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
