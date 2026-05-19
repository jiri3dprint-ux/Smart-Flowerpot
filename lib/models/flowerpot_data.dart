import 'package:flutter/foundation.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final int moisture;
  final double batteryVoltage;
  final double batteryPercent;
  final bool isCharging;
  final int wifiRssi;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.moisture,
    required this.batteryVoltage,
    required this.batteryPercent,
    required this.isCharging,
    required this.wifiRssi,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      moisture: json['moisture'] as int,
      batteryVoltage: (json['battery_voltage'] as num).toDouble(),
      batteryPercent: (json['battery_percent'] as num).toDouble(),
      isCharging: json['is_charging'] as bool,
      wifiRssi: json['wifi_rssi'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

class LEDConfig {
  int mode; // 0-9
  int brightness; // 0-255
  int speed; // 1-100
  List<int> colors; // RGB colors for manual mode (24 LEDs)

  LEDConfig({
    this.mode = 1, // Rainbow
    this.brightness = 128,
    this.speed = 50,
    List<int>? colors,
  }) : colors = colors ?? List.filled(24, 0x00FF00);

  Map<String, dynamic> toJson() {
    return {
      'led_mode': mode,
      'led_brightness': brightness,
      'led_speed': speed,
      'led_colors': colors,
    };
  }
}

class FlowerPotData extends ChangeNotifier {
  SensorData? _currentData;
  final List<SensorData> _history = [];
  LEDConfig _ledConfig = LEDConfig();
  bool _appActive = false;
  int _moistureThreshold = 15;
  
  SensorData? get currentData => _currentData;
  List<SensorData> get history => _history;
  LEDConfig get ledConfig => _ledConfig;
  bool get appActive => _appActive;
  int get moistureThreshold => _moistureThreshold;

  void updateSensorData(SensorData data) {
    _currentData = data;
    _history.add(data);
    
    // Keep only last 7 days (288 samples/day * 7)
    if (_history.length > 2016) {
      _history.removeAt(0);
    }
    
    notifyListeners();
  }

  void updateLEDConfig(LEDConfig config) {
    _ledConfig = config;
    notifyListeners();
  }

  void setAppActive(bool active) {
    _appActive = active;
    notifyListeners();
  }

  void setMoistureThreshold(int threshold) {
    _moistureThreshold = threshold;
    notifyListeners();
  }

  List<SensorData> getHistoryForPeriod(Duration period) {
    final cutoff = DateTime.now().subtract(period);
    return _history.where((d) => d.timestamp.isAfter(cutoff)).toList();
  }
}
