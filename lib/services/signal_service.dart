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

  Future<void> openRadioSettings() async {
    try {
      await _channel.invokeMethod('openRadioSettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: '${e.message}'.");
    }
  }

  Future<String> getCarrierName() async {
    try {
      final String? name = await _channel.invokeMethod('getCarrierName');
      return name ?? "Unknown";
    } on PlatformException catch (e) {
      print("Failed to get carrier name: '${e.message}'.");
      return "Unknown";
    }
  }

  Future<Map<String, dynamic>?> getSignalData(String provider) async {
    try {
      final Map<dynamic, dynamic>? data = await _channel.invokeMethod(
        'getSignalStrength',
        {'provider': provider},
      );
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } on PlatformException catch (e) {
      print("Failed to get signal data: '${e.message}'.");
    }
    return null;
  }
}
