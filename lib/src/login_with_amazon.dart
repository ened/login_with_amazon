part of login_with_amazon;

class LoginWithAmazon {
  static const MethodChannel _channel =
      const MethodChannel('login_with_amazon');

  /// Login using the Amazon SDK.
  /// 
  /// 
  /// Returns [AmazonUser] object when the login has succeeded.
  /// Returns `null` if the login has been cancelled.
  Future<AmazonUser> login() async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('login');

    if (map != null) {
      return AmazonUser(
        email: map['email'],
        userId: map['userId'],
      );
    }

    return null;
  }

  /// Sign Out
  Future<void> signOut() async {
    return await _channel.invokeMethod<void>('signOut');
  }
}
