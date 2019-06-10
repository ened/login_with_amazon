import 'package:flutter/material.dart';

import 'package:login_with_amazon/login_with_amazon.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AmazonUser _user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Login With Amazon'),
          actions: <Widget>[
            if (_user != null)
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: () {
                  LoginWithAmazon().signOut().then((_) {
                    setState(() {
                      _user = null;
                    });
                  });
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: _user != null
                ? Text('eMail: ${_user.email}, ${_user.userId}\n')
                : Text('Please log in'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.person_add),
          onPressed: () async {
            final AmazonUser user = await LoginWithAmazon().login();
            setState(() {
              _user = user;
            });
          },
        ),
      ),
    );
  }
}
