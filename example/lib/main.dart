import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:login_with_amazon/login_with_amazon.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LoginWithAmazon _lwa = LoginWithAmazon();

  Authorization _authorization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<AmazonUser>(
        stream: _lwa.observeUsers,
        builder: (context, userSnapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Login With Amazon'),
                  FutureBuilder<String>(
                    future: _lwa.getSdkVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          'Version: ${snapshot.data}',
                          style: Theme.of(context)
                              .textTheme
                              .body1
                              .apply(color: Colors.white),
                        );
                      }
                      return SizedBox();
                    },
                  )
                ],
              ),
              actions: <Widget>[
                if (userSnapshot.hasData && userSnapshot.data != null)
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () {
                      _lwa.signOut().then((x) {
                        setState(() {
                          _authorization = null;
                        });
                      });
                    },
                  ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Builder(
                  builder: (context) {
                    List<Widget> widgets = [
                      if (userSnapshot.hasData &&
                          userSnapshot.data != null) ...[
                        Text('eMail: ${userSnapshot.data.email}'),
                        Text('userId: ${userSnapshot.data.userId}\n'),
                      ] else
                        Text('Please log in'),
                      if (_authorization != null) ...[
                        Text('Access Token: ${_authorization.accessToken}'),
                        Text(
                            'Authorization Code: ${_authorization.authorizationCode}'),
                        Text('User: ${_authorization.user}'),
                        Text('Client ID: ${_authorization.clientId}'),
                      ],
                      FlatButton(
                        child: Text('Login (authorization code)'),
                        onPressed: _loginAuthCode,
                      ),
                      FlatButton(
                        child: Text('Login (access token)'),
                        onPressed: _loginAccessToken,
                      ),
                    ];

                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      children: widgets,
                    );
                  },
                ),
              ),
            ),
            floatingActionButton:
                !userSnapshot.hasData || userSnapshot.data == null
                    ? FloatingActionButton(
                        child: Icon(Icons.person_add),
                        onPressed: _loginAccessToken)
                    : null,
          );
        },
      ),
    );
  }

  Future<void> _loginAuthCode() async {
    // TODO: Retrieve from another source.
    final str = 'Ni8nooLo eo4Aiqua ohQu1xee';
    final b64 = base64
        .encode(str.codeUnits)
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');

    final digest = sha256.convert(b64.codeUnits).toString();

    final String codeChallenge = digest;
    final String codeChallengeMethod = 'S256';

    final auth = await _lwa.login(
      scopes: {
        'alexa:voice_service:pre_auth' : null,
        "alexa:all": {
          // TODO: Retrieve from AVS.
          'productID': '',
          'productInstanceAttributes': {
            // TODO: Should be unique to a device.
            'deviceSerialNumber': '',
          }
        },
      },
      grantType: GrantType.authorizationCode,
      // The proof key parameters set in this method are only for example and shall not be used.
      proofKeyParameters: ProofKeyParameters(
        codeChallenge: codeChallenge,
        codeChallengeMethod: codeChallengeMethod,
      ),
    );
    if (mounted) {
      setState(() {
        _authorization = auth;
      });
    }
  }

  Future<void> _loginAccessToken() async {
    final auth = await _lwa.login(
      scopes: {
        'profile': null,
        'profile:user_id': null,
      },
      grantType: GrantType.accessToken,
    );
    if (mounted) {
      setState(() {
        _authorization = auth;
      });
    }
  }
}
