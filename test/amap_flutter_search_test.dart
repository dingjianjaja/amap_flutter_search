/*
 * @Author: 丁健
 * @Date: 2022-04-01 08:43:56
 * @LastEditTime: 2022-04-06 11:15:54
 * @LastEditors: 丁健
 * @Description: 
 * @FilePath: /amap_flutter_search/test/amap_flutter_search_test.dart
 * 可以输入预定的版权声明、个性签名、空行等
 */
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yingzi_flutter_amap_search_v2/amap_flutter_search.dart';

void main() {
  const MethodChannel channel = MethodChannel('amap_flutter_search');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await AmapFlutterSearch.platformVersion, '42');
  });
}
