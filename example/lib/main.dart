import 'package:flutter/material.dart';

import 'package:login_with_amazon/login_with_amazon.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LoginWithAmazon _lwa = LoginWithAmazon();

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
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      final user = userSnapshot.data;
                      return Text('eMail: ${user.email}, ${user.userId}\n');
                    }
                    return Text('Please log in');
                  },
                ),
              ),
            ),
            floatingActionButton:
                !userSnapshot.hasData || userSnapshot.data == null
                    ? FloatingActionButton(
                        child: Icon(Icons.person_add),
                        onPressed: () async {
                          _lwa.login(scopes: [
                            LoginWithAmazon.SCOPE_USER_ID,
                            LoginWithAmazon.SCOPE_PROFILE,
                          ]);
                        },
                      )
                    : null,
          );
        },
      ),
    );
  }
}
