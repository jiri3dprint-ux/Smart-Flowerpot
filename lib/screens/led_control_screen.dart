import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/flowerpot_data.dart';
import '../services/mqtt_service.dart';
import 'dart:math' as math;

class LEDControlScreen extends StatefulWidget {
  const LEDControlScreen({Key? key}) : super(key: key);

  @override
  State<LEDControlScreen> createState() => _LEDControlScreenState();
}

class _LEDControlScreenState extends State<LEDControlScreen> {
  static const List<String> animationModes = [
    'Off', 'Rainbow', 'Breathing', 'Comet', 'Sparkle',
    'Wave', 'Pulse', 'Fire', 'Water', 'Manual'
  ];

  int? _selectedLED;

  @override
  Widget build(BuildContext context) {
    final flowerpotData = Provider.of<FlowerPotData>(context);
    final mqttService = Provider.of<MQTTService>(context, listen: false);
    final config = flowerpotData.ledConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Control'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Animation mode selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Animation Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(animationModes.length, (index) {
                      return ChoiceChip(
                        label: Text(animationModes[index]),
                        selected: config.mode == index,
                        onSelected: (selected) {
                          if (selected) {
                            config.mode = index;
                            flowerpotData.updateLEDConfig(config);
                            mqttService.publishConfig(config.toJson());
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Brightness slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Brightness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${config.brightness}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: config.brightness.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    label: config.brightness.toString(),
                    onChanged: (value) {
                      config.brightness = value.toInt();
                      flowerpotData.updateLEDConfig(config);
                    },
                    onChangeEnd: (value) {
                      mqttService.publishConfig(config.toJson());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Speed slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${config.speed}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Slider(
                    value: config.speed.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: config.speed.toString(),
                    onChanged: (value) {
                      config.speed = value.toInt();
                      flowerpotData.updateLEDConfig(config);
                    },
                    onChangeEnd: (value) {
                      mqttService.publishConfig(config.toJson());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Manual LED editor (only visible in manual mode)
          if (config.mode == 9) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manual LED Editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Tap on an LED to change its color', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: CustomPaint(
                          painter: LEDCirclePainter(
                            colors: config.colors,
                            selectedIndex: _selectedLED,
                            onTap: (index) {
                              setState(() => _selectedLED = index);
                              _showColorPicker(config, index, mqttService, flowerpotData);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info card
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('LED Cycle Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('LEDs automatically turn off every 10 minutes for 1 second to save power.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(LEDConfig config, int index, MQTTService mqtt, FlowerPotData data) {
    Color currentColor = Color(config.colors[index] | 0xFF000000);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('LED $index Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                currentColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                config.colors[index] = currentColor.value & 0x00FFFFFF;
                data.updateLEDConfig(config);
                mqtt.publishConfig(config.toJson());
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

class LEDCirclePainter extends CustomPainter {
  final List<int> colors;
  final int? selectedIndex;
  final Function(int) onTap;

  LEDCirclePainter({
    required this.colors,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final angleStep = 2 * math.pi / 24;

    for (int i = 0; i < 24; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final paint = Paint()
        ..color = Color(colors[i] | 0xFF000000)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), i == selectedIndex ? 14 : 12, paint);

      if (i == selectedIndex) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset(x, y), 14, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(LEDCirclePainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => true;
}
