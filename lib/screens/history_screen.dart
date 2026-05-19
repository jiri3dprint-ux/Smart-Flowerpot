import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/flowerpot_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedPeriod = 1; // 0=24h, 1=7days

  @override
  Widget build(BuildContext context) {
    final flowerpotData = Provider.of<FlowerPotData>(context);
    final history = _selectedPeriod == 0
        ? flowerpotData.getHistoryForPeriod(const Duration(days: 1))
        : flowerpotData.getHistoryForPeriod(const Duration(days: 7));

    if (history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('No historical data yet')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period selector
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('24 Hours')),
              ButtonSegment(value: 1, label: Text('7 Days')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<int> selection) {
              setState(() => _selectedPeriod = selection.first);
            },
          ),
          const SizedBox(height: 24),

          // Temperature chart
          _buildChartCard(
            '🌡️ Temperature',
            history.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.temperature,
            )).toList(),
            Colors.red,
            '°C',
          ),

          // Humidity chart
          _buildChartCard(
            '💧 Humidity',
            history.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.humidity,
            )).toList(),
            Colors.blue,
            '%',
          ),

          // Soil moisture chart
          _buildChartCard(
            '🌱 Soil Moisture',
            history.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.moisture.toDouble(),
            )).toList(),
            Colors.green,
            '%',
          ),

          // Battery chart
          _buildChartCard(
            '🔋 Battery',
            history.map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.batteryPercent,
            )).toList(),
            Colors.orange,
            '%',
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<FlSpot> spots, Color color, String unit) {
    if (spots.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}$unit', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
