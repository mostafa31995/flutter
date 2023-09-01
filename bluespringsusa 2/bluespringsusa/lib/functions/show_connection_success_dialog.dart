import 'package:bluespringsusa/functions/show_message_dialog.dart';
import 'package:flutter/material.dart';

showSuccessDialog(BuildContext context, String message, String deviceID) {
  showMessageDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 10,
          ),
          Text(message),
          SizedBox(
            height: 10,
          ),
          Text(
            deviceID,
            textAlign: TextAlign.center,
            textScaleFactor: 2,
          ),
        ],
      ));
}
