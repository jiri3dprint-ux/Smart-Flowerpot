import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  MqttServerClient? _client;
  Function(Map<String, dynamic>)? onDataReceived;
  Function(Map<String, dynamic>)? onNotification;
  
  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  static const String clientId = 'flowerpot_app';
  
  static const String topicData = 'flowerpot/data';
  static const String topicStatus = 'flowerpot/status';
  static const String topicConfig = 'flowerpot/config';
  static const String topicNotification = 'flowerpot/notifications';

  Future<bool> connect() async {
    _client = MqttServerClient.withPort(broker, clientId, port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    
    _client!.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await _client!.connect();
      
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT connected');
        _subscribe();
        return true;
      }
    } catch (e) {
      print('MQTT connection failed: $e');
      _client!.disconnect();
    }
    
    return false;
  }

  void _subscribe() {
    _client!.subscribe(topicData, MqttQos.atMostOnce);
    _client!.subscribe(topicStatus, MqttQos.atMostOnce);
    _client!.subscribe(topicNotification, MqttQos.atMostOnce);
    
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        
        if (messages[0].topic == topicData && onDataReceived != null) {
          onDataReceived!(data);
        } else if (messages[0].topic == topicNotification && onNotification != null) {
          onNotification!(data);
        }
      } catch (e) {
        print('Error parsing MQTT message: $e');
      }
    });
  }

  void publishConfig(Map<String, dynamic> config) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('Not connected to MQTT');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(config));
    _client!.publishMessage(topicConfig, MqttQos.atMostOnce, builder.payload!);
    print('Config published: $config');
  }

  void setAppActive(bool active) {
    publishConfig({'app_active': active});
  }

  void disconnect() {
    _client?.disconnect();
  }

  void _onConnected() {
    print('MQTT connected');
  }

  void _onDisconnected() {
    print('MQTT disconnected');
  }
}
