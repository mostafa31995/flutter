import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluespringsusa/dialogs/scanned_devices_dialog.dart';
import 'package:bluespringsusa/dialogs/scanned_wifi_ssid_dialog.dart';
import 'package:bluespringsusa/dialogs/wifi_details_input_dialog.dart';
import 'package:bluespringsusa/functions/cloud.dart';
import 'package:bluespringsusa/functions/show_confirm_dialog.dart';
import 'package:bluespringsusa/functions/show_connection_success_dialog.dart';
import 'package:bluespringsusa/functions/show_message_dialog.dart';
import 'package:bluespringsusa/main.dart';
import 'package:bluespringsusa/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController webviewcontroller;
  String receivedMessage = "";
  bool isLoading = false;
  String loadingMsg = "";
  BluetoothDevice? connection;
  int error_reload_count = 0;
  String current_requested_page = "";
  @override
  void initState() {
    super.initState();
    webviewcontroller = WebViewController();
    loadWebPage();
  }

  @override
  Widget build(BuildContext context) {
    return Loading(
      isLoading: isLoading,
      loadingText: loadingMsg,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: WebViewWidget(
            controller: webviewcontroller,
          ),
        ),
      ),
    );
  }

  Future setSwtichStateAndColor(
      String deviceID, String switchID, bool isOn) async {
    await webviewcontroller.runJavaScript(
        "\$('.device-card[deviceID=$deviceID] .toggle-wrapper[switchID=$switchID]').find('.toggle-link-contain').removeClass('on');");
    if (isOn) {
      await webviewcontroller.runJavaScript(
          "\$('.device-card[deviceID=$deviceID] .toggle-wrapper[switchID=$switchID]').find('.toggle-link-contain').addClass('on');");
    }
  }

  Future switchToggleClick(
      String deviceID, String switchID, bool dataValue) async {
    setState(() {
      isLoading = true;
      loadingMsg = dataValue ? "Turning ON" : "Turning OFF";
    });
    try {
      await postDataToCloud({switchID: dataValue}, deviceID);
      await setSwtichStateAndColor(
          deviceID, "relay1", cloudSwitchState[deviceID]!["relay1"]!);
      await setSwtichStateAndColor(
          deviceID, "relay2", cloudSwitchState[deviceID]!["relay2"]!);
      await setSwtichStateAndColor(
          deviceID, "aux", cloudSwitchState[deviceID]!["aux1"]!);
      await setSwtichStateAndColor(deviceID, switchID, dataValue);
      await Future.delayed(Duration(milliseconds: 100));
      cloudSwitchState[deviceID]?[switchID] = dataValue;
    } catch (e) {
      await setSwtichStateAndColor(deviceID, switchID, dataValue);
      throw e;
    }
    setState(() {
      isLoading = false;
      loadingMsg = "";
    });
  }

  Future UpdateDevices() async {
    await Future.delayed(Duration(milliseconds: 800));
    // await webviewcontroller.runJavaScript("document.getElementsByClassName(\"device-location-card\")[0].style.display = \"none\"");
    await webviewcontroller
        .runJavaScript("\$('.device-card-contain').html('');");
    for (String deviceID in deviceIDs) {
      await webviewcontroller.runJavaScript(
          "\$('.hide .device-card').clone(true, true).attr('deviceID','$deviceID').prependTo('.device-card-contain');");
      await webviewcontroller.runJavaScript(
          "\$('.device-card[deviceID=$deviceID] .device-location-title').html('${deviceNames[deviceID] ?? "New Building"}');");

      await webviewcontroller.runJavaScript(
          "\$('.device-card[deviceID=$deviceID] .new-schedule-link[switchID=relay1]').attr('src','security-lights-schedules.html?deviceId=$deviceID&switchID=relay1');");
      await webviewcontroller.runJavaScript(
          "\$('.device-card[deviceID=$deviceID] .new-schedule-link[switchID=relay2]').attr('src','sign-lights-schedules.html?deviceId=$deviceID&switchID=relay2');");
      await webviewcontroller.runJavaScript(
          "\$('.device-card[deviceID=$deviceID] .new-schedule-link[switchID=aux1]').attr('src','aux-port-schedules.html?deviceId=$deviceID&switchID=aux1');");

      await loadDataFromCloud(deviceID);
    }
    UpdateSwitchesNames();
  }

  Future UpdateSwitchesNames() async {
    for (String deviceID in deviceSwitchNames.keys) {
      if (deviceSwitchNames[deviceID] != null) {
        Map<String, String> switchNames = deviceSwitchNames[deviceID]!;
        for (String switchID in switchNames.keys) {
          if (switchNames[switchID] != null) {
            await webviewcontroller.runJavaScript(
                "\$('.device-card[deviceID=$deviceID] .control-title-link-wrap[switchID=$switchID] div').eq(0).text('${switchNames[switchID]}')");
          }
        }
      }
    }
  }

  Future loadWebPage() async {
    String deviceID = "";
    await webviewcontroller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await webviewcontroller.addJavaScriptChannel("CallLocal",
        onMessageReceived: ((JavaScriptMessage message) async {
      if (message.message == "SCAN") {
        scanForBluetoothDevices();
      } else if (message.message.startsWith("POWER:")) {
        deviceID = message.message.split(":")[2];
        String switchID = message.message.split(":")[1];
        bool? data = cloudSwitchState[deviceID]?[switchID];

        await switchToggleClick(deviceID, switchID, !(data ?? false));
      } else if (message.message.startsWith("DELETE:")) {
        showConfirmDialog(
                context: context,
                child: Text("Are you sure you want to delete this device?"),
                cancelText: "NO",
                okText: "YES")
            .then((value) async {
          if (value == "YES") {
            String deviceID = message.message.split(":")[1];
            deviceIDs.remove(deviceID);
            var pref = await SharedPreferences.getInstance();
            deviceNames.remove(deviceID);
            await pref.setStringList("deviceIDs", deviceIDs);
            await pref.setString("deviceNames", jsonEncode(deviceNames));
            await UpdateDevices();
          }
        });
      } else if (message.message.startsWith("EDITNAME:")) {
        String deviceID = message.message.split(":")[1];
        String deviceName = deviceNames[deviceID] ?? "";
        showConfirmDialog(
                context: context,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Device Name",
                        labelText: "Enter Device Name",
                      ),
                      minLines: 1,
                      maxLines: 2,
                      initialValue: deviceName,
                      onChanged: (value) {
                        deviceName = value;
                      },
                    ),
                  ],
                ),
                cancelText: "Cancel",
                okText: "Update")
            .then((value) async {
          if (value == "Update") {
            var pref = await SharedPreferences.getInstance();
            deviceNames[deviceID] = deviceName;
            await pref.setString("deviceNames", jsonEncode(deviceNames));
            await UpdateDevices();
          }
        });
      } else if (message.message.startsWith("EDITSWITCHNAME:")) {
        String deviceID = message.message.split(":")[2];
        String switchID = message.message.split(":")[1];
        String switchName = deviceSwitchNames[deviceID]?[switchID] ?? "";
        if (switchName.isEmpty) {
          switchName = (await webviewcontroller.runJavaScriptReturningResult(
                  "\$('.device-card[deviceID=$deviceID] .control-title-link-wrap[switchID=$switchID] div').eq(0).text().trim();"))
              .toString()
              .replaceAll('"', '');
        }
        showConfirmDialog(
                autoCloseMillis: 60000,
                context: context,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Switch Name",
                        labelText: "Enter Switch Name",
                      ),
                      minLines: 1,
                      maxLines: 2,
                      initialValue: switchName,
                      onChanged: (value) {
                        switchName = value;
                      },
                    ),
                  ],
                ),
                cancelText: "Cancel",
                okText: "Update")
            .then((value) async {
          if (value == "Update") {
            var pref = await SharedPreferences.getInstance();
            if (deviceSwitchNames[deviceID] == null) {
              deviceSwitchNames.addAll({deviceID: {}});
            }
            deviceSwitchNames[deviceID]![switchID] = switchName;
            await pref.setString(
                "deviceSwitchNames", jsonEncode(deviceSwitchNames));
            UpdateSwitchesNames();
          }
        });
      }
    }));
    await webviewcontroller.enableZoom(false);

    await webviewcontroller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {},
        onPageFinished: (String url) async {
          if (url.startsWith('http://157.245.246.57/')) {
            await webviewcontroller.runJavaScript(
                "\$('.hide .toggle-wrapper').eq(0).attr('switchID','relay1');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .toggle-wrapper').eq(1).attr('switchID','relay2');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .toggle-wrapper').eq(2).attr('switchID','aux1');");

            await webviewcontroller.runJavaScript(
                "\$('.hide .control-title-link-wrap').eq(0).attr('switchID','relay1');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .control-title-link-wrap').eq(1).attr('switchID','relay2');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .control-title-link-wrap').eq(2).attr('switchID','aux1');");

            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(0).attr('switchID','relay1');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(1).attr('switchID','relay2');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(2).attr('switchID','aux1');");

            // await webviewcontroller.runJavaScript("\$('.hide .new-schedule-link').eq(0).attr('href','security-lights-schedules.html');");
            // await webviewcontroller.runJavaScript("\$('.hide .new-schedule-link').eq(1).attr('href','sign-lights-schedules.html');");
            // await webviewcontroller.runJavaScript("\$('.hide .new-schedule-link').eq(2).attr('href','aux-port-schedules.html');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(0).attr('href','new-schedule.html');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(1).attr('href','new-schedule.html');");
            await webviewcontroller.runJavaScript(
                "\$('.hide .new-schedule-link').eq(2).attr('href','new-schedule.html');");

            await webviewcontroller.runJavaScript(
                "\$('.hide .control-title-link-wrap').attr('href','#');");

            await webviewcontroller
                .runJavaScript("\$('.add-icon-link').off('click');");
            await webviewcontroller.runJavaScript(
                "\$('.add-icon-link').on('click',function(){CallLocal.postMessage('SCAN');});");

            await webviewcontroller
                .runJavaScript("\$('.toggle-wrapper').off();");
            await webviewcontroller.runJavaScript(
                "\$('.toggle-wrapper').on('click',function(){ CallLocal.postMessage('POWER:'+\$(this).attr('switchID')+':'+\$(this).closest('.device-card').attr('deviceID')); return false;});");

            await webviewcontroller
                .runJavaScript("\$('.card-delete-btn').off();");
            await webviewcontroller.runJavaScript(
                "\$('.card-delete-btn').on('click',function(){CallLocal.postMessage('DELETE:'+\$(this).closest('.device-card').attr('deviceID')); return false;});");

            await webviewcontroller.runJavaScript("\$('.editable').off();");
            await webviewcontroller.runJavaScript(
                "\$('.editable').on('click',function(){ CallLocal.postMessage('EDITNAME:'+\$(this).closest('.device-card').attr('deviceID')); return false;});");

            await webviewcontroller
                .runJavaScript("\$('.control-title-link-wrap').off();");
            await webviewcontroller.runJavaScript(
                "\$('.control-title-link-wrap').on('click',function(){ CallLocal.postMessage('EDITSWITCHNAME:'+\$(this).attr('switchID')+':'+\$(this).closest('.device-card').attr('deviceID')); return false;});");

            await UpdateDevices();
          }
        },
        onWebResourceError: (WebResourceError error) async {
          if (error_reload_count < 5) {
            error_reload_count += 1;
            await webviewcontroller
                .loadRequest(Uri.parse(current_requested_page));
          } else {
            webviewcontroller.loadHtmlString(
                "<br/><br/><br/><br/><center><h1><b>Unable to connect to server<br/>Please check your internet s</b></h1></center>");
          }
        },
      ),
    );
    await webviewcontroller
        .loadRequest(Uri.parse('http://157.245.246.57/?token=$deviceID'));
  }

  Future showScannedBluetoothDevicesDialog() async {
    setState(() {
      loadingMsg = "Connecting";
      isLoading = true;
    });
    await connection?.connect();

    if (await connection?.connectionState.first ==
        BluetoothConnectionState.connected) {
      await Future.delayed(Duration(seconds: 1));
      // await connection?.discoverServices();
      debugPrint('Connected to the device');
      if (mounted) {
        setState(() {
          loadingMsg = "";
          isLoading = false;
        });
      }
      await showMessageDialog(
          child: Text("Connected successfully"), context: context);

      // for (BluetoothService service in connection!) {
      //   for (BluetoothCharacteristic characteristic
      //       in service.characteristics) {
      //     var value = await characteristic.read();
      //     print(value);
      //     // Uint8List data;
      //     receivedMessage += ascii.decode(value);
      //     print("355 working $receivedMessage");
      //     if (value.last == 10) {
      //       debugPrint('Data incoming2: ${receivedMessage.trim()}');
      //     }
      //
      //     // print(AsciiDecoder().convert(value)); /*** TAG-1***/
      //     // print(utf8.decode(value)); /*** TAG-2***/
      //     // if (characteristic.properties.write){
      //     //   if (characteristic.properties.notify){
      //     //     _rx_Write_Characteristic = characteristic;
      //     //     _sendCommandToDevice();
      //     //   }
      //     // }
      //   }
      // }

      // connection?.input?.listen((Uint8List data) {
      //   receivedMessage += ascii.decode(data);
      //   if (data.last == 10) {
      //     debugPrint('Data incoming2: ${receivedMessage.trim()}');
      //   }
      // }).onDone(() {
      //   receivedMessage = "";
      //   debugPrint('Disconnected by remote request');
      //   if (mounted) {
      //     ScaffoldMessenger.of(context)
      //         .showSnackBar(const SnackBar(content: Text("Disconnected")));
      //     setState(() {});
      //   }
      // });
      await showScannedWifiSsidDialog();
    }
  }

  Future showScannedWifiSsidDialog() async {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 130),
            child: ScannedWifiSsidDialog(),
          );
        }).then(
      (ssid) async {
        if (ssid == null) {
          // connection?.close();
          setState(() {
            loadingMsg = "";
            isLoading = false;
          });
          return;
        }
        await showWifiDetailsInputDialog(ssid);
      },
    );
  }

  Future showWifiDetailsInputDialog(String ssid) async {
    showDialog(
        context: context,
        builder: (context) {
          return WifiDetailsInputDialog(
            ssid: ssid,
          );
        }).then((value) async {
      if (value == null) {
        // connection?.close();
        setState(() {
          loadingMsg = "";
          isLoading = false;
        });
        return;
      }
      if (mounted) {
        setState(() {
          loadingMsg = "Waiting for device to confirm the details";
          isLoading = true;
        });
      }
      String ssid = value["ssid"];
      String password = value["password"];
      await sendWifiDetailsDataToBluetoothDevice(ssid, password);
    });
  }

  Future sendWifiDetailsDataToBluetoothDevice(
      String ssid, String password) async {
    receivedMessage = "";
    List<BluetoothService>? services = await connection?.discoverServices();
    if (services != null) {
      services.forEach((service) async {
        // Reads all characteristics
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          List<int> value = await c.read();
          print(value);
          receivedMessage += ascii.decode(value);
          c.write(ascii.encode("BLUE_SSID:$ssid\n"));
          c.write(ascii.encode("BLUE_PASSWORD:$password\n"));
          if (ascii.decode(value).trim().startsWith("SUCCESS:")) {
            String deviceID = receivedMessage.trim().replaceAll("SUCCESS:", "");
            if (deviceIDs.contains(deviceID)) {
              deviceIDs.remove(deviceID);
            }
            deviceIDs.add(deviceID);
            addDeviceName(deviceID);
          }
        }
      });
    }

    var time = DateTime.now().millisecondsSinceEpoch;
    while (receivedMessage.trim() != "SSID_OK") {
      await Future.delayed(const Duration(milliseconds: 100));
      if (DateTime.now().millisecondsSinceEpoch - time > 200000) {
        // connection?.close();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Timed out")));
          setState(() {
            loadingMsg = "";
            isLoading = false;
          });
        }
        return;
      }
    }

    receivedMessage = "";
    // connection?.output.add(ascii.encode("BLUE_PASSWORD:$password\n"));
    time = DateTime.now().millisecondsSinceEpoch;
    while (receivedMessage.trim() != "PASS:OK") {
      await Future.delayed(const Duration(milliseconds: 100));
      if (DateTime.now().millisecondsSinceEpoch - time > 200000) {
        // connection?.close();
        if (mounted) {
          setState(() {
            loadingMsg = "";
            isLoading = false;
          });
          await showMessageDialog(child: Text("Timed out"), context: context);
        }
        return;
      }
    }
    receivedMessage = "";
    time = DateTime.now().millisecondsSinceEpoch;
    while (receivedMessage.trim().isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (DateTime.now().millisecondsSinceEpoch - time > 200000) {
        // connection?.close();
        if (mounted) {
          setState(() {
            loadingMsg = "";
            isLoading = false;
          });
          await showMessageDialog(child: Text("Timed out"), context: context);
        }

        return;
      }
    }
    if (receivedMessage.trim().startsWith("SUCCESS:")) {
      String deviceID = receivedMessage.trim().replaceAll("SUCCESS:", "");
      if (deviceIDs.contains(deviceID)) {
        deviceIDs.remove(deviceID);
      }
      deviceIDs.add(deviceID);
      addDeviceName(deviceID);
    } else {
      await showMessageDialog(child: Text("Failed!!"), context: context);
    }
    // connection?.close();
  }

  void addDeviceName(String deviceID) {
    String deviceName = "";
    showConfirmDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              hintText: "Device Name",
              labelText: "Enter Device Name",
            ),
            minLines: 1,
            maxLines: 2,
            onChanged: (value) {
              deviceName = value;
            },
          ),
        ],
      ),
    ).then((value) async {
      if (value == "Ok") {
        deviceNames[deviceID] = deviceName;
      }
      var pref = await SharedPreferences.getInstance();
      await pref.setStringList("deviceIDs", deviceIDs);
      await pref.setString("deviceNames", jsonEncode(deviceNames));
      await UpdateDevices();
      if (mounted) {
        setState(() {
          loadingMsg = "";
          isLoading = false;
        });
      }
      showSuccessDialog(context, "Successfully connected to", deviceID);
    });
  }

  Future scanForBluetoothDevices() async {
    var state = await FlutterBluePlus.turnOn();
    var adapterState = FlutterBluePlus.adapterState;
    if (adapterState.first == BluetoothAdapterState.on) {
      await showMessageDialog(
          child: Text("Turn on Bluetooth feature"), context: context);
      return;
    }
    // if ((connection?.isConnected ?? false)) {
    //   await connection?.close(); // Closing connection
    //   return;
    // }
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 130),
            child: ScannedDevicesDialog(),
          );
        }).then((value) async {
      try {
        if (value == null) return;
        connection = value;
        await showScannedBluetoothDevicesDialog();
      } catch (exception) {
        receivedMessage = "";
        debugPrint('Cannot connect, exception occured');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error connecting\n\n" + exception.toString())));
      }
      setState(() {
        loadingMsg = "";
        isLoading = false;
      });
    });
  }
}
