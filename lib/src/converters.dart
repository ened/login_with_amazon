import 'package:login_with_amazon/login_with_amazon.dart';

AmazonUser mapToAmazonUser(Map<dynamic, dynamic> map) {
  return AmazonUser(
    email: map['email'],
    userId: map['userId'],
  );
}

Authorization mapToAuthorization(Map<dynamic, dynamic> map) {
  return Authorization(
    accessToken: map['accessToken'],
    authorizationCode: map['authorizationCode'],
    clientId: map['clientId'],
    redirectURI: map['redirectURI'],
    user: mapToAmazonUser(map['user']),
  );
}
