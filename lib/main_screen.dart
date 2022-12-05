import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:test_flutter_bt/bluetooth_connector.dart';

class ScanResultWrapper {
  String mac;
  ScanResult scanResult;

  ScanResultWrapper(this.mac, this.scanResult);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const CUSTOM_DEVICE_ID = 123;
  static const CUSTOM_DEVICE_MAC_PREFIX = '5A:12:3B';

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  int _deviceCount = 0;
  int _rssi = 0;

  Map<String, ScanResult> customDevices = Map();

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: <Widget>[
          Text('Custom devices: $_deviceCount'),
          Text('rssi: $_rssi'),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: const Text('run command'),
              onPressed: runCommandPressed,
            ),
          )
        ]),
      ),
    );
  }

  void runCommandPressed() async {
    flutterBlue.stopScan();
    print(customDevices);
    ScanResultWrapper bestScanResult = _getBestRssi(customDevices);
    doSomething(bestScanResult.scanResult);
  }

  Future<void> doSomething(ScanResult bestScanResult) async {
    BluetoothConnector bluetoothConnector =
        BluetoothConnector(bestScanResult.device);
    await bluetoothConnector.connect();
    await bluetoothConnector.writeMessage([1, 2, 3]);
    await bluetoothConnector.disconnect();
  }

  void startScan() {
    flutterBlue.startScan(
      timeout: const Duration(seconds: 60),
      //withServices: [Guid('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx')],
    );
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.advertisementData.manufacturerData[CUSTOM_DEVICE_ID] != null) {
          print(
              'manufacturerData: ${r.advertisementData.manufacturerData[CUSTOM_DEVICE_ID]}');
        }
        String macAddress = _getMacFromScanResult(r);
        print('calculated macAddress: $macAddress');
        customDevices[macAddress] = r;
        if (customDevices.isEmpty) {
          _rssi = 0;
        } else {
          ScanResult bestScanResult = _getBestRssi(customDevices).scanResult;
          _rssi = bestScanResult.rssi;
        }
        setState(() {
          _deviceCount = customDevices.length;
        });
      }
    });
  }

  ScanResultWrapper _getBestRssi(Map<String, ScanResult> customDevices) {
    List<ScanResultWrapper> sortedKeys = [];
    customDevices.forEach((k, v) => sortedKeys.add(ScanResultWrapper(k, v)));
    var best = sortedKeys[0];
    for (var element in sortedKeys) {
      if (element.scanResult.rssi != 0 &&
          element.scanResult.rssi > best.scanResult.rssi) {
        best = element;
      }
    }
    return best;
  }

  String getShortAddress(String longAddress) {
    return longAddress.replaceAll(':', '').toLowerCase();
  }

  /// iOS devices does not show Mac for security reasons
  String _getMacFromScanResult(ScanResult scanResult) {
    List<int> manufacturerData =
        scanResult.advertisementData.manufacturerData[CUSTOM_DEVICE_ID]!;
    // [version, part6, part5, part4, ...]
    String part4 = manufacturerData[3].toRadixString(16).padLeft(2, '0');
    String part5 = manufacturerData[2].toRadixString(16).padLeft(2, '0');
    String part6 = manufacturerData[1].toRadixString(16).padLeft(2, '0');
    return '$CUSTOM_DEVICE_MAC_PREFIX:$part4:$part5:$part6'.toUpperCase();
  }
}
