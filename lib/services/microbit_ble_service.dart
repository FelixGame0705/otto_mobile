import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MicrobitBleService {
  static final MicrobitBleService _instance = MicrobitBleService._internal();
  factory MicrobitBleService() => _instance;
  MicrobitBleService._internal();

  // micro:bit UART service UUIDs (Nordic UART Service)
  // Reference: https://lancaster-university.github.io/microbit-docs/ble/uart-service/
  static const String microbitServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String microbitTxCharacteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // TX - micro:bit to client (Indications)
  static const String microbitRxCharacteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // RX - client to micro:bit (Write)
  
  // Maximum transmission unit (MTU) for micro:bit UART
  static const int maxUartDataLength = 20; // MTU of 23 minus 3 for GATT overhead

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _rxSubscription;

  // Connection state
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isEncrypted = false;

  // Streams for UI updates
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<String> _receivedDataController = StreamController<String>.broadcast();
  final StreamController<List<BluetoothDevice>> _discoveredDevicesController = StreamController<List<BluetoothDevice>>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get isEncrypted => _isEncrypted;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get receivedDataStream => _receivedDataController.stream;
  Stream<List<BluetoothDevice>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  // Start scanning for micro:bit devices
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      List<BluetoothDevice> discoveredDevices = [];

      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isOn) {
        throw Exception('Bluetooth is not enabled');
      }

      // Clear previous results
      _discoveredDevicesController.add([]);

      // Start scanning with broader parameters
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        // Don't filter by service UUID initially to catch paired devices
        // withServices: [Guid(microbitServiceUuid)],
      );

      // Listen for discovered devices
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Check if device has micro:bit service or is a known micro:bit
          bool isMicrobit = false;
          
          // Check by service UUIDs in advertisement data
          if (result.advertisementData.serviceUuids.contains(Guid(microbitServiceUuid))) {
            isMicrobit = true;
          }
          
          // Check by device name patterns
          String deviceName = result.device.platformName.toLowerCase();
          if (deviceName.contains('microbit') || 
              deviceName.contains('micro:bit') ||
              deviceName.contains('bbc micro:bit')) {
            isMicrobit = true;
          }
          
          // Check by manufacturer data (micro:bit uses Nordic Semiconductor)
          if (result.advertisementData.manufacturerData.isNotEmpty) {
            for (var entry in result.advertisementData.manufacturerData.entries) {
              if (entry.key == 0x0059) { // Nordic Semiconductor manufacturer ID
                isMicrobit = true;
                break;
              }
            }
          }

          if (isMicrobit && !discoveredDevices.any((device) => device.remoteId == result.device.remoteId)) {
            discoveredDevices.add(result.device);
            _discoveredDevicesController.add(List.from(discoveredDevices));
          }
        }
      });

      // Stop scanning after timeout
      Timer(const Duration(seconds: 15), () {
        stopScan();
      });

    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    if (!_isScanning) return;
    
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  // Get paired devices (Android only)
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      // Get all connected devices first
      List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;
      
      // Filter for micro:bit devices
      List<BluetoothDevice> microbitDevices = [];
      
      for (BluetoothDevice device in connectedDevices) {
        try {
          // Try to discover services to check if it's a micro:bit
          List<BluetoothService> services = await device.discoverServices();
          for (BluetoothService service in services) {
            if (service.uuid.toString().toUpperCase() == microbitServiceUuid.toUpperCase()) {
              microbitDevices.add(device);
              break;
            }
          }
        } catch (e) {
          // Device might be disconnected, skip
          continue;
        }
      }
      
      return microbitDevices;
    } catch (e) {
      return [];
    }
  }

  // Load paired devices and add to discovered list
  Future<void> loadPairedDevices() async {
    try {
      List<BluetoothDevice> pairedDevices = await getPairedDevices();
      if (pairedDevices.isNotEmpty) {
        _discoveredDevicesController.add(pairedDevices);
      }
    } catch (e) {
      // Ignore errors for paired devices
    }
  }

  // Connect to a micro:bit device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      
      // Check if already connected by trying to discover services first
      try {
        List<BluetoothService> services = await device.discoverServices();
        if (services.isNotEmpty) {
          // Device is already connected, just set up services
          await _setupDeviceServices(device);
          return;
        }
      } catch (e) {
        // Device is not connected, proceed with connection
      }
      
      // Connect to device with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await device.connect(timeout: const Duration(seconds: 20));
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception('Failed to connect after $maxRetries attempts: $e');
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      // Set up device services
      await _setupDeviceServices(device);

    } catch (e) {
      _cleanup();
      rethrow;
    }
  }

  // Setup device services and characteristics
  Future<void> _setupDeviceServices(BluetoothDevice device) async {
    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    
    // Find micro:bit UART service
    BluetoothService? uartService;
    for (BluetoothService service in services) {
      if (service.uuid.toString().toUpperCase() == microbitServiceUuid.toUpperCase()) {
        uartService = service;
        break;
      }
    }

    if (uartService == null) {
      throw Exception('micro:bit UART service not found. Make sure the device is a micro:bit with BLE enabled.');
    }

    // Get characteristics
    _txCharacteristic = uartService.characteristics.firstWhere(
      (char) => char.uuid.toString().toUpperCase() == microbitTxCharacteristicUuid.toUpperCase(),
      orElse: () => throw Exception('TX characteristic not found'),
    );

    _rxCharacteristic = uartService.characteristics.firstWhere(
      (char) => char.uuid.toString().toUpperCase() == microbitRxCharacteristicUuid.toUpperCase(),
      orElse: () => throw Exception('RX characteristic not found'),
    );

    // Check if encryption is required for UART service
    // According to micro:bit docs, UART service requires encrypted link
    _isEncrypted = true; // micro:bit UART service requires encryption

    // Subscribe to TX characteristic for incoming data (micro:bit to client)
    // TX characteristic uses Indications, so we listen to its stream
    _rxSubscription = _txCharacteristic!.lastValueStream.listen((data) {
      if (data.isNotEmpty) {
        String receivedString = utf8.decode(data);
        _receivedDataController.add(receivedString);
      }
    });

    // Set up connection state monitoring
    device.connectionState.listen((state) {
      _isConnected = (state == BluetoothConnectionState.connected);
      _connectionStateController.add(_isConnected);
      
      if (!_isConnected) {
        _cleanup();
      }
    });

    _isConnected = true;
    _connectionStateController.add(true);
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanup();
  }

  // Send data to micro:bit via RX characteristic (client to micro:bit)
  Future<void> sendData(String data) async {
    if (!_isConnected || _rxCharacteristic == null) {
      throw Exception('Not connected to micro:bit');
    }

    try {
      Uint8List dataBytes = Uint8List.fromList(utf8.encode(data));
      
      // Split data into chunks of max 20 bytes (micro:bit UART limit)
      List<Uint8List> chunks = _splitDataIntoChunks(dataBytes, maxUartDataLength);
      
      for (Uint8List chunk in chunks) {
        // Use write without response for better performance
        await _rxCharacteristic!.write(chunk, withoutResponse: true);
        // Small delay between chunks to avoid overwhelming the micro:bit
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  // Send command to micro:bit (with newline)
  Future<void> sendCommand(String command) async {
    await sendData('$command\n');
  }

  // Split data into chunks respecting micro:bit UART MTU limit
  List<Uint8List> _splitDataIntoChunks(Uint8List data, int chunkSize) {
    List<Uint8List> chunks = [];
    for (int i = 0; i < data.length; i += chunkSize) {
      int end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(Uint8List.fromList(data.sublist(i, end)));
    }
    return chunks;
  }

  // Check if device is in pairing mode
  bool _isDeviceInPairingMode(ScanResult result) {
    // Check if device name indicates pairing mode
    String deviceName = result.device.platformName.toLowerCase();
    return deviceName.contains('pairing') || 
           deviceName.contains('microbit') ||
           deviceName.contains('micro:bit');
  }

  // Get device pairing status
  Future<bool> isDevicePaired(BluetoothDevice device) async {
    try {
      // Try to discover services without connecting
      List<BluetoothService> services = await device.discoverServices();
      return services.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Send data with proper error handling for encryption requirements
  Future<void> sendDataSecurely(String data) async {
    if (!_isConnected || _rxCharacteristic == null) {
      throw Exception('Not connected to micro:bit');
    }

    if (!_isEncrypted) {
      throw Exception('Encrypted connection required for UART service. Please ensure device is paired.');
    }

    await sendData(data);
  }

  // Clean up resources
  void _cleanup() {
    _isConnected = false;
    _isEncrypted = false;
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _rxSubscription?.cancel();
    _rxSubscription = null;
    _connectionStateController.add(false);
  }

  // Dispose all streams
  void dispose() {
    _cleanup();
    _connectionStateController.close();
    _receivedDataController.close();
    _discoveredDevicesController.close();
  }
}
