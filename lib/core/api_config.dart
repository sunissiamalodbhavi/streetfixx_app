import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiConfig {
  // ---------------------------------------------------------------------------
  // TODO: REPLACE THIS WITH YOUR LAPTOP'S LOCAL IP ADDRESS
  // How to find it:
  // Windows: Open Command Prompt -> type 'ipconfig' -> Look for IPv4 Address
  // Mac/Linux: Open Terminal -> type 'ifconfig' -> Look for inet address
  static const String laptopIp = '192.168.0.162'; 
  // ---------------------------------------------------------------------------

  static const String _emulatorUrl = 'http://192.168.0.162:5000';
  static const String _webUrl = 'http://192.168.0.162:5000';
  
  static String _baseUrl = _emulatorUrl; // Default to emulator

  static String get baseUrl => _baseUrl;

  /// Initializes the API configuration by detecting the environment.
  /// Call this in main.dart before runApp().
  static Future<void> init() async {
    if (kIsWeb) {
      _baseUrl = _webUrl;
      debugPrint('API Config: Running on Web. Base URL: $_baseUrl');
      return;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // isPhysicalDevice returns true if running on a real device
      if (androidInfo.isPhysicalDevice) {
        _baseUrl = 'http://$laptopIp:5000';
        debugPrint('API Config: Running on Physical Android Device. Base URL: $_baseUrl');
      } else {
        _baseUrl = _emulatorUrl;
        debugPrint('API Config: Running on Android Emulator. Base URL: $_baseUrl');
      }
    } else {
      // Fallback for iOS or other platforms (assuming simulator for now)
      _baseUrl = _webUrl; // or some other default
       debugPrint('API Config: Running on other platform. Base URL: $_baseUrl');
    }
  }
}
