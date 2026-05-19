import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flowerpot_data.dart';
import '../services/mqtt_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final flowerpotData = Provider.of<FlowerPotData>(context);
    final mqttService = Provider.of<MQTTService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Moisture threshold
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Moisture Alert Threshold'),
            subtitle: Text('${flowerpotData.moistureThreshold}% (Alert when below)'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showThresholdDialog(flowerpotData, mqttService),
            ),
          ),
          const Divider(),

          // App info
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('Smart Flowerpot v1.0.0\nESP32-C6 with AHT20, MAX17048\n24x SK6812 LEDs'),
          ),
          const Divider(),

          // MQTT info
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('MQTT Broker'),
            subtitle: const Text('broker.hivemq.com:1883'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reconnecting...')),
                );
                await mqttService.connect();
              },
            ),
          ),
          const Divider(),

          // Hardware info
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hardware', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('MCU: ESP32-C6 MINI'),
                Text('Sensors: AHT20, MAX17048, Soil Moisture'),
                Text('LEDs: 24x SK6812MINI-E'),
                Text('Battery: 1000mAh LiPo + Wireless Charging'),
              ],
            ),
          ),

          // Pin info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pin Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildPinRow('GPIO18', 'LED MOSFET'),
                  _buildPinRow('GPIO19', 'LED Data'),
                  _buildPinRow('GPIO20', 'I2C SCL'),
                  _buildPinRow('GPIO23', 'I2C SDA'),
                  _buildPinRow('GPIO0', 'Soil Moisture'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinRow(String pin, String function) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(pin, style: const TextStyle(fontFamily: 'monospace'))),
          Text('→ $function'),
        ],
      ),
    );
  }

  void _showThresholdDialog(FlowerPotData data, MQTTService mqtt) {
    int tempThreshold = data.moistureThreshold;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Moisture Alert Threshold'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You will be notified when moisture drops below this level.'),
                  const SizedBox(height: 16),
                  Text('${tempThreshold}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: tempThreshold.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 45,
                    label: '$tempThreshold%',
                    onChanged: (value) {
                      setState(() => tempThreshold = value.toInt());
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Recommended for cactus: 10-20%', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    data.setMoistureThreshold(tempThreshold);
                    mqtt.publishConfig({'moisture_threshold': tempThreshold});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Threshold set to $tempThreshold%')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
