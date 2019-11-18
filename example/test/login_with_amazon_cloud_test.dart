import 'package:e2e/e2e.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_with_amazon/login_with_amazon.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  test('Call SDK version', () async {
    expect(await LoginWithAmazon().getSdkVersion(), '3.0.6');
  });
}
