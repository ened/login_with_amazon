part of login_with_amazon;

enum GrantType {
  accessToken,
  authorizationCode,
}

/// https://developer.amazon.com/it/docs/dash/lwa-mobile-sdk.html#prerequisites
class ProofKeyParameters {
  ProofKeyParameters({
    @required this.codeChallenge,
    @required this.codeChallengeMethod,
  });

  final String codeChallenge;
  final String codeChallengeMethod;
}

class LoginWithAmazon {
  static const MethodChannel _channel =
      const MethodChannel('com.github.ened/login_with_amazon');

  static const EventChannel _userStreamChannel =
      const EventChannel('com.github.ened/login_with_amazon/user');

  static const EventChannel _authorizationStreamChannel =
      const EventChannel('com.github.ened/login_with_amazon/authorization');

  Stream<AmazonUser> get observeUsers =>
      _userStreamChannel.receiveBroadcastStream().map<AmazonUser>((map) {
        print('<<< $map');
        if (map != null) {
          return mapToAmazonUser(map);
        } else {
          return null;
        }
      });

  Stream<Authorization> get observeAuthorization => _authorizationStreamChannel
          .receiveBroadcastStream()
          .map<Authorization>((map) {
        print('<<< $map');
        if (map != null) {
          return mapToAuthorization(map);
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
  /// Returns [Authorization] object when the login has succeeded.
  /// Returns `null` if the login has been cancelled.
  Future<Authorization> login({
    /// List of scopes to request.
    /// The client is responsible for picking the correct scope names.
    Map<String, dynamic> scopes = const {},

    /// Grant Type
    GrantType grantType = GrantType.accessToken,
    ProofKeyParameters proofKeyParameters,
  }) async {
    assert(
        grantType == GrantType.accessToken ||
            (grantType == GrantType.authorizationCode &&
                proofKeyParameters != null),
        'You must set proofKeyParameters when using the authorization code grant type.');

    var arguments = {
      'scopes': scopes,
      'grantType': grantType == GrantType.accessToken
          ? 'access_token'
          : 'authorization_code',
    };

    if (grantType == GrantType.authorizationCode) {
      arguments['codeChallenge'] = proofKeyParameters.codeChallenge;
      arguments['codeChallengeMethod'] = proofKeyParameters.codeChallengeMethod;
    }

    return _channel
        .invokeMethod<Map<dynamic, dynamic>>('login', arguments)
        .then<Authorization>((map) => mapToAuthorization(map));
  }

  /// Sign Out
  Future<void> signOut() async {
    return await _channel.invokeMethod<void>('signOut');
  }
}
