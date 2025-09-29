import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ottobit/services/microbit_ble_service.dart';

class MicrobitConnectionScreen extends StatefulWidget {
  const MicrobitConnectionScreen({super.key});

  @override
  State<MicrobitConnectionScreen> createState() => _MicrobitConnectionScreenState();
}

class _MicrobitConnectionScreenState extends State<MicrobitConnectionScreen> {
  final MicrobitBleService _bleService = MicrobitBleService();
  List<BluetoothDevice> _discoveredDevices = [];
  String _receivedData = '';
  Map<String, int> _buttonStates = {'buttonA': 0, 'buttonB': 0};
  final TextEditingController _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupListeners();
    // Load paired devices on startup
    _loadPairedDevices();
  }

  void _setupListeners() {
    // Listen for discovered devices
    _bleService.discoveredDevicesStream.listen((devices) {
      setState(() {
        _discoveredDevices = devices;
      });
    });

    // Listen for received data
    _bleService.receivedDataStream.listen((data) {
      setState(() {
        _receivedData += data;
      });
    });

    // Listen for button state changes
    _bleService.buttonStateStream.listen((buttonData) {
      setState(() {
        _buttonStates.addAll(buttonData);
      });
    });

    // Listen for connection state changes
    _bleService.connectionStateStream.listen((isConnected) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _loadPairedDevices() async {
    try {
      await _bleService.loadPairedDevices();
    } catch (e) {
      // Ignore errors for paired devices
    }
  }

  Future<void> _startScan() async {
    try {
      // Check Bluetooth state first
      if (!await FlutterBluePlus.isOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable Bluetooth first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _bleService.startScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scanning for micro:bit devices...')),
        );
      }
    } catch (e) {
      print('Scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.platformName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _bleService.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from micro:bit')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnect error: $e')),
        );
      }
    }
  }

  Future<void> _sendCommand() async {
    if (_commandController.text.trim().isEmpty) return;

    try {
      await _bleService.sendCommand(_commandController.text.trim());
      _commandController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Command sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send error: $e')),
        );
      }
    }
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
    });
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nếu không thể kết nối với micro:bit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Đảm bảo micro:bit đã được flash code BLE'),
              Text('2. Reset micro:bit (nút reset hoặc tháo pin)'),
              Text('3. Đóng tất cả app khác đang kết nối với micro:bit'),
              Text('4. Kiểm tra quyền Bluetooth và Location'),
              Text('5. Nhấn "Refresh" để kiểm tra thiết bị đã paired'),
              Text('6. Nhấn "Scan" để tìm thiết bị mới'),
              SizedBox(height: 8),
              Text(
                'Code mẫu cho micro:bit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Sử dụng MicroBitUARTService trong code'),
              Text('• Enable BLE services trong MicroBitConfig.h'),
              Text('• Đảm bảo micro:bit đang ở chế độ pairing'),
              SizedBox(height: 8),
              Text(
                'Lưu ý: micro:bit chỉ có thể kết nối với một thiết bị tại một thời điểm.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _bleService.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _bleService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _bleService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                if (_bleService.isConnected && _bleService.isEncrypted) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.lock,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Encrypted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
            if (_bleService.connectedDevice != null) ...[
              const SizedBox(height: 8),
              Text('Device: ${_bleService.connectedDevice!.platformName}'),
              Text('ID: ${_bleService.connectedDevice!.remoteId}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButtonStatus() {
    if (!_bleService.isConnected) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Button States',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildButtonIndicator('Button A', _buttonStates['buttonA'] ?? 0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButtonIndicator('Button B', _buttonStates['buttonB'] ?? 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonIndicator(String label, int state) {
    String stateText;
    Color stateColor;
    
    switch (state) {
      case 0:
        stateText = 'Not Pressed';
        stateColor = Colors.grey;
        break;
      case 1:
        stateText = 'Pressed';
        stateColor = Colors.green;
        break;
      case 2:
        stateText = 'Long Press';
        stateColor = Colors.orange;
        break;
      default:
        stateText = 'Unknown';
        stateColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: stateColor),
        borderRadius: BorderRadius.circular(8),
        color: stateColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            stateText,
            style: TextStyle(
              color: stateColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadPairedDevices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _bleService.isScanning ? null : _startScan,
                      icon: _bleService.isScanning 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                      label: Text(_bleService.isScanning ? 'Scanning...' : 'Scan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_discoveredDevices.isEmpty)
              Column(
                children: [
                  const Text('No micro:bit devices found.'),
                  const SizedBox(height: 8),
                  const Text('• Tap "Refresh" to check paired devices'),
                  const Text('• Tap "Scan" to search for micro:bit devices'),
                  const Text('• Make sure micro:bit is powered on and BLE is enabled'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showTroubleshootingDialog(),
                    icon: const Icon(Icons.help),
                    label: const Text('Troubleshooting Guide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _discoveredDevices[index];
                  final isConnected = _bleService.connectedDevice?.remoteId == device.remoteId;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.bluetooth,
                        color: isConnected ? Colors.green : Colors.blue,
                      ),
                      title: Text(
                        device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                        style: TextStyle(
                          fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(device.remoteId.toString()),
                      trailing: isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _connectToDevice(device),
                            child: const Text('Connect'),
                          ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Commands',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command to send...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _bleService.isConnected ? _sendCommand : null,
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _bleService.isConnected ? _disconnect : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearReceivedData,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Received Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _clearReceivedData,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[50],
              ),
              child: SingleChildScrollView(
                child: Text(
                  _receivedData.isEmpty ? 'No data received yet...' : _receivedData,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('micro:bit Connection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            _buildButtonStatus(),
            const SizedBox(height: 16),
            _buildDeviceList(),
            const SizedBox(height: 16),
            _buildCommandSection(),
            const SizedBox(height: 16),
            _buildReceivedDataSection(),
          ],
        ),
      ),
    );
  }
}
