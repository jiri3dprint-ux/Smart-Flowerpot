import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flowerpot_data.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
import 'led_control_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late MQTTService _mqttService;
  late NotificationService _notificationService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final flowerpotData = Provider.of<FlowerPotData>(context, listen: false);
    
    if (state == AppLifecycleState.resumed) {
      flowerpotData.setAppActive(true);
      _mqttService.setAppActive(true);
    } else if (state == AppLifecycleState.paused) {
      flowerpotData.setAppActive(false);
      _mqttService.setAppActive(false);
    }
  }

  Future<void> _initServices() async {
    _mqttService = Provider.of<MQTTService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    
    await _notificationService.initialize();
    
    _mqttService.onDataReceived = (data) {
      final flowerpotData = Provider.of<FlowerPotData>(context, listen: false);
      flowerpotData.updateSensorData(SensorData.fromJson(data));
    };
    
    _mqttService.onNotification = (data) {
      _notificationService.showLocalNotification(
        'Plant Alert! 🌵',
        data['message'] ?? 'Your plant needs attention',
      );
    };
    
    final connected = await _mqttService.connect();
    setState(() => _isConnected = connected);
    
    if (connected) {
      final flowerpotData = Provider.of<FlowerPotData>(context, listen: false);
      flowerpotData.setAppActive(true);
      _mqttService.setAppActive(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Flowerpot'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            color: _isConnected ? Colors.green : Colors.red,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isConnected ? 'Connected' : 'Disconnected')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FlowerPotData>(
        builder: (context, data, child) {
          if (data.currentData == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for data...'),
                ],
              ),
            );
          }

          final sensor = data.currentData!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plant status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('🌵', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 8),
                        Text(
                          _getPlantStatus(sensor.moisture),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sensor readings
                Row(
                  children: [
                    Expanded(child: _buildSensorCard('🌡️', 'Temperature', '${sensor.temperature.toStringAsFixed(1)}°C')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSensorCard('💧', 'Humidity', '${sensor.humidity.toStringAsFixed(1)}%')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSensorCard('🌱', 'Soil Moisture', '${sensor.moisture}%', 
                      color: sensor.moisture < data.moistureThreshold ? Colors.red : Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSensorCard('🔋', 'Battery', '${sensor.batteryPercent.toStringAsFixed(0)}%',
                      subtitle: sensor.isCharging ? 'Charging' : '${sensor.batteryVoltage.toStringAsFixed(2)}V')),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSensorCard('📶', 'WiFi Signal', '${sensor.wifiRssi} dBm'),

                const SizedBox(height: 24),

                // Action buttons
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LEDControlScreen()),
                    );
                  },
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('LED Control'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorCard(String emoji, String label, String value, {String? subtitle, Color? color}) {
    return Card(
      color: color?.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  String _getPlantStatus(int moisture) {
    if (moisture < 15) return 'Thirsty!';
    if (moisture < 30) return 'Getting Dry';
    if (moisture < 60) return 'Happy';
    return 'Well Watered';
  }
}
