import 'dart:async';

import 'package:flutter/material.dart';

class WifiDetailsInputDialog extends StatefulWidget {
  const WifiDetailsInputDialog({super.key, required this.ssid});

  final String ssid;
  @override
  State<WifiDetailsInputDialog> createState() => _WifiDetailsInputDialogState();
}

class _WifiDetailsInputDialogState extends State<WifiDetailsInputDialog> {
  String ssid = "";
  String password = "";
  @override
  void initState() {
    super.initState();
    ssid = widget.ssid;
    Timer.run(() {
      fn1.requestFocus();
    });
  }

  FocusNode fn1 = FocusNode();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      clipBehavior: Clip.antiAlias,
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text("Wifi Details"),
            backgroundColor: Color.fromARGB(255, 231, 232, 240),
            foregroundColor: Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      hintText: "Enter Wifi SSID",
                      labelText: "Wifi SSID",
                    ),
                    initialValue: widget.ssid,
                    readOnly: true,
                    minLines: 1,
                    maxLines: 2,
                    onChanged: (value) {
                      ssid = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Enter Wifi Password",
                      labelText: "Wifi Password",
                    ),
                    focusNode: fn1,
                    obscureText: true,
                    onChanged: (value) {
                      password = value;
                    },
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          //     child: ElevatedButton(
          //       child: Text("Proceed"),
          //       onPressed: () {
          //         Navigator.pop(context, {"ssid": ssid, "password": password});
          //       },
          //     ),
          //   ),
          // )
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ButtonStyle(
              // backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 231, 232, 240)),
              backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 197, 203, 242)),
              foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.black),
            ),
            child: Text("Proceed"),
            onPressed: () {
              Navigator.pop(context, {"ssid": ssid, "password": password});
            },
          ),
        )
      ],
    );
  }
}
