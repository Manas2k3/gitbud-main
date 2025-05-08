import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../secrets.dart';

class CallAppInfo {
  static int get appId {
    final id = ZEGOCLOUD_APP_ID;
    if (id.isEmpty) {
      throw Exception('ZEGOCLOUD_APP_ID is not set in the .env file');
    }
    return int.parse(id);
  }

  static String get appSign {
    final sign = ZEGOCLOUD_APP_SIGN;
    if (sign.isEmpty) {
      throw Exception('ZEGOCLOUD_APP_SIGN is not set in the .env file');
    }
    return sign;
  }
}
