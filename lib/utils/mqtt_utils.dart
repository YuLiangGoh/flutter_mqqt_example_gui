import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttUtils {
  late MqttServerClient client;

  Future<void> connect(
      String broker, String clientId, String userName, String password) async {
    client = MqttServerClient(broker, '');
    client.logging(on: true);
    client.setProtocolV311();
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.port = 1883;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect(userName, password);
      debugPrint('EXAMPLE::Mosquitto client connected');
    } on NoConnectionException catch (e) {
      debugPrint('EXAMPLE::client exception - $e');
      client.disconnect();
      rethrow;
    } on SocketException catch (e) {
      debugPrint('EXAMPLE::socket exception - $e');
      client.disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      client.disconnect();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> subscribeTo(String topic) async {
    try {
      client.subscribe(topic, MqttQos.atLeastOnce);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unsubscribeFrom(String topic) async {
    try {
      client.unsubscribe(topic);
    } catch (e) {
      rethrow;
    }
  }

  void onDisconnected() {
    debugPrint('OnDisconnected client callback - Client disconnection');
  }

  void onConnected() {
    debugPrint('OnConnected client callback - Client connection was sucessful');
  }

  void onSubscribed(String topic) {
    debugPrint('Subscription confirmed for topic $topic');
  }

  void onUnsubscribed(String? topic) {
    debugPrint('Unsubscription confirmed for topic $topic');
  }

  void onSubscribeFail(String topic) {
    debugPrint('Failed to subscribe to the topic $topic');
  }

  void pong() {
    debugPrint('Ping response client callback invoked');
  }

  void onMessage() {
    try {
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        debugPrint(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
        debugPrint('');
      });
    } catch (e) {
      rethrow;
    }
  }

  void publish(String topic, String message) {
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } catch (e) {
      rethrow;
    }
  }
}
