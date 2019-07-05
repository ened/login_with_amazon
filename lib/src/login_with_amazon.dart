part of login_with_amazon;

class LoginWithAmazon {
  static const String SCOPE_USER_ID = 'userId';
  static const String SCOPE_PROFILE = 'profile';
  static const String SCOPE_POSTAL_CODE = 'postalCode';

  static const MethodChannel _channel =
      const MethodChannel('com.github.ened/login_with_amazon');

  static const EventChannel _userStreamChannel =
      const EventChannel('com.github.ened/login_with_amazon/user');

  Stream<AmazonUser> get observeUsers =>
      _userStreamChannel.receiveBroadcastStream().map<AmazonUser>((map) {
        print('<<< $map');
        if (map != null) {
          return AmazonUser(
            email: map['email'],
            userId: map['userId'],
          );
        } else {
          return null;
        }
      });

  /// Returns the current Amazon LWA SDK version (native component).
  Future<String> getSdkVersion() => _channel.invokeMethod<String>('version');

  /// Login using the Amazon SDK.
  /// 
  /// [scopes] must not be empty.
  ///
  /// Returns [AmazonUser] object when the login has succeeded.
  /// Returns `null` if the login has been cancelled.
  Future<AmazonUser> login({
    /// List of scopes to request.
    /// Must contain [SCOPE_USER_ID], [SCOPE_PROFILE] or [SCOPE_POSTAL_CODE].
    List<String> scopes = const [],
  }) async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('login', {
      'scopes': scopes,
    });

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
