import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Map<String, Map<String, bool>> cloudSwitchState = {};

Future postDataToCloud(Map data, String deviceID) async {
  String apiUrl = "https://iot.accensysenergy.com:8080/api/v1/$deviceID/attributes";
  var response = await http.post(
    Uri.parse(apiUrl),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(data),
  );
  debugPrint("Response body :" + response.body.toString());
  if (response.statusCode != 200) {
    throw Exception("error in posting");
  }
}

Future loadDataFromCloud(String deviceID) async {
  String apiUrl = "https://iot.accensysenergy.com:8080/api/v1/$deviceID/attributes?clientKeys=relay1,relay2,aux1,timer1,timer2";
  var response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (cloudSwitchState[deviceID] == null) {
      cloudSwitchState.addAll({
        deviceID: {
          "relay1": data["client"]["relay1"],
          "relay2": data["client"]["relay2"],
          "aux1": data["client"]["aux1"],
        }
      });
    }
    cloudSwitchState[deviceID]!["relay1"] = data["client"]["relay1"];
    cloudSwitchState[deviceID]!["relay2"] = data["client"]["relay2"];
    cloudSwitchState[deviceID]!["aux1"] = data["client"]["aux1"];
  }
}
