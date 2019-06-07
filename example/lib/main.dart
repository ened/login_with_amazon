import 'package:flutter/material.dart';

import 'package:login_with_amazon/login_with_amazon.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('eMail: $_email\n'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final String email = await LoginWithAmazon().login();
            setState(() {
              _email = email;
            });
          },
        ),
      ),
    );
  }
}
