import 'package:login_with_amazon/login_with_amazon.dart';

AmazonUser mapToAmazonUser(Map<dynamic, dynamic> map) {
  if (map.isNotEmpty) {
    return AmazonUser(
      email: map['email'],
      userId: map['userId'],
    );
  }

  return null;
}

Authorization mapToAuthorization(Map<dynamic, dynamic> map) {
  if (map == null || map.isEmpty) {
    return null;
  }

  return Authorization(
    accessToken: map['accessToken'],
    authorizationCode: map['authorizationCode'],
    clientId: map['clientId'],
    redirectURI: map['redirectURI'],
    user: mapToAmazonUser(map['user']),
  );
}
