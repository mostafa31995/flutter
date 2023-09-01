import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<dynamic> showConfirmDialog({
  required Widget child,
  required BuildContext context,
  String cancelText = "Cancel",
  String okText = "Ok",
  int autoCloseMillis = 30000,
}) {
  return showDialog(
      barrierDismissible: false,
      context: context,
      builder: ((dialogcontext) {
        int startime = DateTime.now().millisecondsSinceEpoch;

        ValueNotifier<String> timePassed = ValueNotifier("");
        var setTime = (int tmpp) {
          int _ss = tmpp.toDouble() ~/ 1000;
          timePassed.value = "${_ss ~/ 60}:${NumberFormat("00").format(_ss % 60)}";
        };
        setTime(autoCloseMillis);
        var tmrr = Timer.periodic(Duration(milliseconds: 1000), ((tmr) {
          try {
            Navigator.canPop(dialogcontext);
            int tmP = DateTime.now().millisecondsSinceEpoch - startime;
            setTime(autoCloseMillis - tmP);
            if (tmP > autoCloseMillis) {
              tmr.cancel();
              Navigator.pop(dialogcontext);
            }
          } catch (_) {
            tmr.cancel();
          }
        }));
        return AlertDialog(
          content: child,
          contentPadding: EdgeInsets.all(30),
          // title: Text("Info"),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Color.fromARGB(255, 231, 232, 240),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          // backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 231, 232, 240)),
                          backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 197, 203, 242)),
                          foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.black),
                        ),
                        onPressed: (() {
                          tmrr.cancel();
                          Navigator.pop(context, cancelText);
                        }),
                        child: Text(cancelText),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          // backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 231, 232, 240)),
                          backgroundColor: MaterialStateProperty.resolveWith((states) => Color.fromARGB(255, 197, 203, 242)),
                          foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.black),
                        ),
                        onPressed: (() {
                          tmrr.cancel();
                          Navigator.pop(context, okText);
                        }),
                        child: Text(okText),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                    valueListenable: timePassed,
                    builder: (context, _, __) {
                      return Text(
                        "Autocloses in ${timePassed.value}",
                        textScaleFactor: 0.6,
                        style: TextStyle(color: Color.fromARGB(255, 81, 10, 10)),
                      );
                    }),
              ],
            ),
          ],
        );
      }));
}
