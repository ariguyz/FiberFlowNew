import 'package:flutter/material.dart';

enum CoreStatus { free, used, fault }

CoreStatus parseCoreStatus(String? raw) {
  switch (raw) {
    case 'used':
      return CoreStatus.used;
    case 'fault':
      return CoreStatus.fault;
    case 'free':
    default:
      return CoreStatus.free;
  }
}

String coreStatusToString(CoreStatus s) {
  switch (s) {
    case CoreStatus.used:
      return 'used';
    case CoreStatus.fault:
      return 'fault';
    case CoreStatus.free:
      return 'free';
  }
}

Color coreColor(CoreStatus s) {
  switch (s) {
    case CoreStatus.used:
      return Colors.green;
    case CoreStatus.fault:
      return Colors.red;
    case CoreStatus.free:
      return Colors.grey;
  }
}
