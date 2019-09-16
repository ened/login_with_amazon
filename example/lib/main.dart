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
                      _lwa.signOut();
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
                      if (_authorization != null)
                        Text('Access Token: ${_authorization.accessToken}')
                    ];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
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
                        onPressed: () async {
                          final auth = await _lwa.login(scopes: [
                            LoginWithAmazon.SCOPE_USER_ID,
                            LoginWithAmazon.SCOPE_PROFILE,
                          ]);
                          if (mounted) {
                            setState(() {
                              _authorization = auth;
                            });
                          }
                        },
                      )
                    : null,
          );
        },
      ),
    );
  }
}
