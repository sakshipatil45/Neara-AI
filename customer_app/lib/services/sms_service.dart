import 'package:flutter_sms/flutter_sms.dart';

/// Sends emergency SMS to a list of phone numbers.
class SmsService {
  /// Sends an emergency SMS containing the [summary] and [locationLink]
  /// to all [phones] in the list.
  ///
  /// On Android: silently sends SMS in background (requires SEND_SMS permission).
  /// On iOS: opens Messages app pre-filled (OS restriction).
  static Future<void> sendEmergencySms({
    required List<String> phones,
    required String summary,
    required String locationLink,
  }) async {
    if (phones.isEmpty) return;

    final message = '$summary\n\nLive Location:\n$locationLink';

    try {
      await sendSMS(
        message: message,
        recipients: phones,
      );
    } catch (_) {
      // Silently ignore — SMS may still have been sent on Android
      // On iOS this throws if Messages app is not opened
    }
  }
}
