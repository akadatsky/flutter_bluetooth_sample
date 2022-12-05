import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class BluetoothConnector {
  static const GATT_CUSTOM_SERVICE_UUID =
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx';
  static const READ_WITH_NOTIFICATIONS_CHARACTERISTIC_UUID =
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx';
  static const WRITE_CHARACTERISTIC_UUID =
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx';
  static const WRITE_WITHOUT_ACK_CHARACTERISTIC_UUID =
      'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx';

  late BluetoothDevice device;
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  bool readDone = true;
  List<int> buff = [];
  late int commandType;
  late int commandLength;

  BluetoothConnector(this.device);

  Future<void> disconnect() async {
    await device.disconnect();
  }

  Future<void> connect() async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    BluetoothService? bluetoothService;
    for (var service in services) {
      if (service.uuid.toString() == GATT_CUSTOM_SERVICE_UUID) {
        bluetoothService = service;
      }
    }

    if (bluetoothService != null &&
        bluetoothService.characteristics.length >= 3) {
      List<BluetoothCharacteristic> characteristics =
          bluetoothService.characteristics;

      for (var ch in characteristics) {
        if (ch.uuid.toString() == READ_WITH_NOTIFICATIONS_CHARACTERISTIC_UUID) {
          _readCharacteristic = ch;
        }
        if (ch.uuid.toString() == WRITE_WITHOUT_ACK_CHARACTERISTIC_UUID) {
          _writeCharacteristic = ch;
        }
      }

      if (_readCharacteristic != null && _writeCharacteristic != null) {
        _readCharacteristic?.value.listen(onRawDataReceived);
        await _readCharacteristic?.setNotifyValue(true);
      }
    }
  }

  void onRawDataReceived(List<int>? value) async {
    if (value == null || value.isEmpty) {
      return;
    }
    // TODO handle
  }

  Future<void> writeMessage(List<int> message) async {
    const BUFFER_SIZE = 20;
    List<List<int>> parts = _split(message, BUFFER_SIZE);
    for (var part in parts) {
      await _writeCharacteristic?.write(part, withoutResponse: true);
      // TODO figure out why it does not work without pause
      sleep(const Duration(milliseconds: 20));
    }
  }

  List<List<int>> _split(List<int> message, int bufferSize) {
    List<List<int>> result = [];
    for (int i = 0; i < message.length; i += bufferSize) {
      int end = i + bufferSize;
      if (i + bufferSize > message.length) {
        end = message.length;
      }
      result.add(message.sublist(i, end));
    }
    return result;
  }
}
