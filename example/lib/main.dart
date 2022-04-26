/*
 * @Author: 丁健
 * @Date: 2022-04-01 08:43:58
 * @LastEditTime: 2022-04-26 09:43:08
 * @LastEditors: 丁健
 * @Description: 
 * @FilePath: /amap_flutter_search/example/lib/main.dart
 * 可以输入预定的版权声明、个性签名、空行等
 */
import 'package:amap_flutter_search_example/test.dart';
import 'package:amap_flutter_search_example/test_map_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:yingzi_flutter_amap_search_v2/amap_flutter_search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await AmapFlutterSearch.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: YZHomePage(),
    );
  }
}

class YZHomePage extends StatefulWidget {
  const YZHomePage({Key? key}) : super(key: key);

  @override
  State<YZHomePage> createState() => _YZHomePageState();
}

class _YZHomePageState extends State<YZHomePage> {
  String _platformVersion = 'Unknown';
  List<AMapPoi> dataList = [];
  late TextEditingController textEditingController;

  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return YZTestMapPage();
                }));
              },
              icon: Icon(Icons.map_outlined))
        ],
      ),
      body: Column(
        children: [
          TextButton.icon(
              onPressed: () {
                AmapFlutterSearch.setApiKey('3b4acde13d0603ecbea0b74781eafaf3',
                    'df6898859be82405b9b41d8d1f1e86d3');
                AmapFlutterSearch.updatePrivacyAgree(true);
                AmapFlutterSearch.updatePrivacyShow(true, true);
              },
              icon: const Icon(Icons.login),
              label: const Text('注册id')),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController,
                  ),
                ),
                TextButton.icon(
                    onPressed: () async {
                      dataList = await AmapFlutterSearch.searchKeyword(
                          textEditingController.text,
                          page: 1,
                          pageSize: 5);
                      setState(() {});
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('搜索')),
              ],
            ),
          ),
          TextButton.icon(
              onPressed: () async {
                dataList = await AmapFlutterSearch.searchAround(
                    Location(latitude: 23.110081, longitude: 113.401344),
                    keyword: textEditingController.text);
                setState(() {});
              },
              icon: const Icon(Icons.search),
              label: const Text('搜索')),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(dataList[index].name ?? ''),
                  subtitle: Text(dataList[index].address ?? ''),
                  trailing: Text('距离:${dataList[index].distance}米'),
                );
              },
              itemCount: dataList.length,
            ),
          ),
        ],
      ),
    );
  }
}
