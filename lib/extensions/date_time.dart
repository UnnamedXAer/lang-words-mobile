import 'dart:io';

import 'package:intl/intl.dart';

extension DateParsing on DateTime {
  String format() {
    return DateFormat.yMMMd(Platform.localeName).add_Hm().format(this);
  }
}
