import 'package:flutter_test/flutter_test.dart';
import 'package:instrumentation_adapter/instrumentation_adapter.dart';
import 'package:login_with_amazon/login_with_amazon.dart';

void main() {
  InstrumentationAdapterFlutterBinding.ensureInitialized();

  test('Call SDK version', () async {
    expect(await LoginWithAmazon().getSdkVersion(), '3.0.6');
  });
}
