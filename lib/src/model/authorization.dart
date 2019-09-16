part of login_with_amazon;

class Authorization {
  Authorization({
    this.accessToken,
    this.authorizationCode,
    this.clientId,
    this.redirectURI,
  });

  final String accessToken;
  final String authorizationCode;
  final String clientId;
  final String redirectURI;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authorization &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          authorizationCode == other.authorizationCode &&
          clientId == other.clientId &&
          redirectURI == other.redirectURI;

  @override
  int get hashCode =>
      accessToken.hashCode ^
      authorizationCode.hashCode ^
      clientId.hashCode ^
      redirectURI.hashCode;

  @override
  String toString() {
    return 'Authorization{accessToken: $accessToken, authorizationCode: $authorizationCode, clientId: $clientId, redirectURI: $redirectURI}';
  }
}
