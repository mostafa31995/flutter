import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'package:wifi_scan/wifi_scan.dart';

class ScannedWifiSsidDialog extends StatefulWidget {
  const ScannedWifiSsidDialog({super.key});

  @override
  State<ScannedWifiSsidDialog> createState() => _ScannedWifiSsidDialogState();
}

class _ScannedWifiSsidDialogState extends State<ScannedWifiSsidDialog> {
  bool isDiscovering = true;

  List<WiFiAccessPoint> accessPoints = [];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;

  void _startDiscovery() async {
    debugPrint(Platform.operatingSystemVersion);
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    isDiscovering = true;
    await _startListeningToScannedResults();
    await _startScan();
  }

  Future _startScan() async {
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    switch (can) {
      case CanStartScan.yes:
        final isScanning = await WiFiScan.instance.startScan();
        break;
      case CanStartScan.notSupported:
        break;
      case CanStartScan.noLocationPermissionRequired:
        break;
      case CanStartScan.noLocationPermissionDenied:
        break;
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        break;
      case CanStartScan.noLocationServiceDisabled:
        break;
      case CanStartScan.failed:
        break;
    }
  }

  Future _startListeningToScannedResults() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    switch (can) {
      case CanGetScannedResults.yes:
        // listen to onScannedResultsAvailable stream
        subscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
          // update accessPoints
          setState(() => accessPoints = results);
        });
        break;
      case CanGetScannedResults.notSupported:
        break;
      case CanGetScannedResults.noLocationPermissionRequired:
        break;
      case CanGetScannedResults.noLocationPermissionDenied:
        break;
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        break;
      case CanGetScannedResults.noLocationServiceDisabled:
        break;
    }
  }

  void _getScannedResults() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    switch (can) {
      case CanGetScannedResults.yes:
        final accessPoints = await WiFiScan.instance.getScannedResults();
        break;
      case CanGetScannedResults.notSupported:
        break;
      case CanGetScannedResults.noLocationPermissionRequired:
        break;
      case CanGetScannedResults.noLocationPermissionDenied:
        break;
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        break;
      case CanGetScannedResults.noLocationServiceDisabled:
        break;
    }
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
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select WIFI SSID"),
        backgroundColor: Color.fromARGB(255, 231, 232, 240),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: (accessPoints
                  .map((e) => e.centerFrequency0.toString().startsWith("5")
                      ? Container()
                      : Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Card(
                            // color: Theme.of(context).primaryColor.withOpacity(0.3),
                            color: Color.fromARGB(255, 230, 230, 238),
                            elevation: 5,
                            child: ListTile(
                              horizontalTitleGap: 0,
                              leading: Icon(Icons.wifi),
                              trailing: ElevatedButton(
                                style: ButtonStyle(
                                  // backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 231, 232, 240)),
                                  backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 197, 203, 242)),
                                  foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.black),
                                ),
                                child: Text("Select"),
                                onPressed: () {
                                  Navigator.pop(context, e.ssid);
                                },
                              ),
                              selectedColor: Colors.red,
                              title: Text(e.ssid),
                              // subtitle: Text(e.centerFrequency0.toString()),
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
