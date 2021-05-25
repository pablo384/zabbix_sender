import 'dart:convert';
import 'dart:io';

import 'byte_stream.dart';

class Datum {
  String? host;
  String? key;
  double? value;

  Datum({
    this.host,
    this.key,
    this.value,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        host: json['host'],
        key: json['key'],
        value: json['value'],
      );

  Map<String, dynamic> toJson() => {
        'host': host,
        'key': key,
        'value': value,
      };
}

class ZabbixSender {
  String? request;
  List<Datum>? data;

  ZabbixSender({
    this.request = 'sender data',
    this.data,
  }) {
    data ??= [];
  }
  factory ZabbixSender.fromJson(Map<String, dynamic> json) => ZabbixSender(
        request: json['request'],
        data: List<Datum>.from(json['data'].map((x) => Datum.fromJson(x))),
      );

  String get toJsonString => jsonEncode(toJson());

  void addItem(String host, String key, double value) {
    data!.add(
      Datum(
        host: host,
        value: value,
        key: key,
      ),
    );
  }

  Future<void> sendData({
    String? host,
    required int port,
  }) async {
    try {
      var socket = await Socket.connect(host, port);
      var header = ByteStream(5 + 4 + 4);
      var payload = ByteStream();
      payload.writeAsciiString(toJsonString);
      header.writeAsciiString('ZBXD\x01');
      header.writeInt32LE(payload.length);
      header.writeAsciiString('\x00\x00\x00\x00');
      socket.add([...header.bytes, ...payload.bytes]);
      await socket.close();
      data!.clear();
    } catch (e, i) {
      print(e.toString());
      print(i.toString());
    }
  }

  Map<String, dynamic> toJson() => {
        'request': request,
        'data': List<dynamic>.from(data!.map((x) => x.toJson())),
      };

  static Future<bool> registerHost({
    String? host,
    required int port,
    String? hostClient,
    String? hostMetadata,
  }) async {
    try {
      var data = <String, String?>{
        'request': 'active checks',
        'host': hostClient,
        'host_metadata': hostMetadata
      };
      var dataString = jsonEncode(data);
      var socket = await Socket.connect(host, port);
      var header = ByteStream(5 + 4 + 4);
      var payload = ByteStream();
      payload.writeAsciiString(dataString);
      header.writeAsciiString('ZBXD\x01');
      header.writeInt32LE(payload.length);
      header.writeAsciiString('\x00\x00\x00\x00');
      socket.add([...header.bytes, ...payload.bytes]);
      await socket.close();
      data.clear();
      return true;
    } catch (e, i) {
      print(e.toString());
      print(i.toString());
      return false;
    }
  }

  static ZabbixSender ZabbixSenderFromJson(String str) {
    final jsonData = json.decode(str);
    return ZabbixSender.fromJson(jsonData);
  }

  static String ZabbixSenderToJson(ZabbixSender data) {
    final dyn = data.toJson();
    return json.encode(dyn);
  }
}
