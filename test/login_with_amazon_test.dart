import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_with_amazon/login_with_amazon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.github.ened/login_with_amazon');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '1.0.0';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getSdkVersion', () async {
    expect(await LoginWithAmazon().getSdkVersion(), '1.0.0');
  });
}
