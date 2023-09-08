import 'dart:developer' as devtools show log;

import 'package:flutter/foundation.dart';

extension DebugPrint on Object {
  void log() {
    if (kDebugMode) devtools.log(toString());
  }
}
