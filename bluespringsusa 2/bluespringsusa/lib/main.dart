import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bluespringsusa/views/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> deviceIDs = [];
Map<String, String> deviceNames = {};
Map<String, Map<String, String>> deviceSwitchNames = {};

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  await Future.delayed(Duration(milliseconds: 500));
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  var pref = await SharedPreferences.getInstance();
  String deviceID = pref.getString("deviceID") ?? "";
  try {
    deviceIDs = pref.getStringList("deviceIDs") ?? [];
  } catch (e) {}
  try {
    deviceNames = Map<String, String>.from(jsonDecode(pref.getString("deviceNames") ?? ""));
  } catch (e) {}
  if (kDebugMode) {
    if (deviceIDs.isEmpty) {
      deviceIDs.add("y8B7EKuusgGygRDH9R2W");
    }
  }
  try {
    String data = pref.getString("deviceSwitchNames") ?? "";
    var json = jsonDecode(data);
    Map<String, dynamic> temp1 = Map<String, dynamic>.from(json);
    for (String key1 in temp1.keys) {
      Map<String, String> temp2 = Map<String, String>.from(temp1[key1]);
      deviceSwitchNames.addAll({key1: temp2});
    }
  } catch (e) {}
  // deviceIDs.add("deviceID");
  if (deviceID.isNotEmpty) {
    deviceIDs.add(deviceID);
    pref.setString("deviceID", "");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blue Springs USA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Blue Springs USA'),
    );
  }
}
