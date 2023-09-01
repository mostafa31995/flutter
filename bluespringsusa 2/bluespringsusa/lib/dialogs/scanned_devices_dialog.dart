import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class ScannedDevicesDialog extends StatefulWidget {
  const ScannedDevicesDialog({super.key});

  @override
  State<ScannedDevicesDialog> createState() => _ScannedDevicesDialogState();
}

class _ScannedDevicesDialogState extends State<ScannedDevicesDialog> {
  StreamSubscription<List<ScanResult>>? _streamSubscription;
  List<ScanResult> results = List<ScanResult>.empty(growable: true);
  bool isDiscovering = true;

  void _startDiscovery() async {
    debugPrint(Platform.operatingSystemVersion);
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    isDiscovering = true;
    FlutterBluePlus.startScan();
    _streamSubscription = FlutterBluePlus.scanResults.listen((rList) {
      for (ScanResult r in rList) {
        print('${r.device.localName} found! rssi: ${r.rssi}');
        final existingIndex = results.indexWhere(
            (element) => element.device.remoteId.str == r.device.remoteId.str);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          results.add(r);
        }
        if (mounted) setState(() {});
      }
    });
    // _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
    //   final existingIndex = results.indexWhere((element) => element.device.address == r.device.address);
    //   if (existingIndex >= 0) {
    //     results[existingIndex] = r;
    //   } else {
    //     results.add(r);
    //   }
    //   if (mounted) setState(() {});
    // });

    _streamSubscription!.onDone(() {
      isDiscovering = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer.run(
      () {
        _startDiscovery();
      },
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    // FlutterBluetoothSerial.instance.cancelDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available devices"),
        backgroundColor: Color.fromARGB(255, 231, 232, 240),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: (results
                  .map((e) => Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Card(
                          // color: Theme.of(context).primaryColor.withOpacity(0.3),
                          color: Color.fromARGB(255, 230, 230, 238),
                          elevation: 5,
                          child: ListTile(
                            horizontalTitleGap: 0,
                            leading: Icon(Icons.bluetooth_connected),
                            trailing: ElevatedButton(
                              style: ButtonStyle(
                                // backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 231, 232, 240)),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith(
                                        (states) =>
                                            Color.fromARGB(255, 197, 203, 242)),
                                foregroundColor:
                                    MaterialStateProperty.resolveWith(
                                        (states) => Colors.black),
                              ),
                              child: Text("Connect"),
                              onPressed: () {
                                Navigator.pop(context, e.device);
                              },
                            ),
                            selectedColor: Colors.red,
                            title: Text(e.device.localName != ""
                                ? e.device.localName
                                : "[NO NAME]"),
                            subtitle: Text(e.device.remoteId.str ?? ""),
                            // onTap: () async {
                            //   Navigator.pop(context, e.device.address);
                            // },
                          ),
                        ),
                      ))
                  .toList()) +
              (!isDiscovering
                  ? []
                  : [
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    ]),
        ),
      )),
    );
  }
}
