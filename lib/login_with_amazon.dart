import 'dart:async';

import 'package:flutter/services.dart';

class LoginWithAmazon {
  static const MethodChannel _channel =
      const MethodChannel('login_with_amazon');

  /// Login &* return email
  Future<String> login() async {
    return await _channel.invokeMethod<String>('login');
  }
}
