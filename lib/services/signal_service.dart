import 'package:flutter/services.dart';

class SignalService {
  static const MethodChannel _channel = MethodChannel('com.signalx/stabilizer');

  Future<void> startStabilizer() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      print("Failed to start stabilizer: '${e.message}'.");
    }
  }

  Future<void> stopStabilizer() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print("Failed to stop stabilizer: '${e.message}'.");
    }
  }
}
