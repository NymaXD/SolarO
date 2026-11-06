import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_o/services/api_config.dart';

void main() {
  test('usa el host del emulador Android en debug', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(ApiConfig.baseUrl, 'http://10.0.2.2:5000');
  });
}
