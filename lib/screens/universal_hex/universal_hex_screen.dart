import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ottobit/services/universal_hex_service.dart';
import 'package:ottobit/services/usb_service.dart';

class UniversalHexScreen extends StatefulWidget {
  const UniversalHexScreen({super.key});

  @override
  State<UniversalHexScreen> createState() => _UniversalHexScreenState();
}

class _UniversalHexScreenState extends State<UniversalHexScreen> {
  final TextEditingController _pythonController = TextEditingController();
  final UsbService _usbService = UsbService();
  
  String? _v1Hex;
  String? _v2Hex;
  String? _universalHex;
  Map<String, dynamic>? _selectedDevice;
  bool _isBuilding = false;
  bool _isFlashing = false;
  int _estimatedSize = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirmware();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await UniversalHexService.initialize();
      // USB service không cần initialize
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize services: $e';
      });
    }
  }

  Future<void> _loadFirmware() async {
    try {
      _v1Hex = await UniversalHexService.loadFirmwareHex('v1');
      _v2Hex = await UniversalHexService.loadFirmwareHex('v2');
    } catch (e) {
      setState(() {
        _error = 'Failed to load firmware: $e';
      });
    }
  }

  Future<void> _buildUniversalHex() async {
    if (_v1Hex == null || _v2Hex == null) {
      setState(() {
        _error = 'Firmware not loaded';
      });
      return;
    }

    final pythonCode = _pythonController.text.trim();
    if (pythonCode.isEmpty) {
      setState(() {
        _error = 'Please enter Python code';
      });
      return;
    }

    setState(() {
      _isBuilding = true;
      _error = null;
    });

    try {
      // Get estimated size first
      final size = await UniversalHexService.getEstimatedSize(
        v1Hex: _v1Hex!,
        v2Hex: _v2Hex!,
        mainPy: pythonCode,
      );

      // Build Universal Hex
      final universalHex = await UniversalHexService.buildUniversalHex(
        v1Hex: _v1Hex!,
        v2Hex: _v2Hex!,
        mainPy: pythonCode,
      );

      setState(() {
        _universalHex = universalHex;
        _estimatedSize = size;
        _isBuilding = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to build Universal Hex: $e';
        _isBuilding = false;
      });
    }
  }

  Future<void> _flashHex() async {
    if (_universalHex == null) {
      setState(() {
        _error = 'Please build Universal Hex first';
      });
      return;
    }

    if (_selectedDevice == null) {
      setState(() {
        _error = 'Please select a USB device';
      });
      return;
    }

    setState(() {
      _isFlashing = true;
      _error = null;
    });

    try {
      // Kết nối với thiết bị USB
      final connected = await _usbService.connectToDevice(_selectedDevice!);
      if (!connected) {
        throw Exception('Failed to connect to USB device');
      }

      // Flash hex file qua USB
      final success = await _usbService.flashHexFile(_universalHex!);
      if (!success) {
        throw Exception('Failed to flash hex file');
      }

      setState(() {
        _isFlashing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hex file flashed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to flash: $e';
        _isFlashing = false;
      });
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _error = null;
    });
    
    try {
      // Kiểm tra xem có micro:bit nào được kết nối không
      final isConnected = await _usbService.isMicrobitConnected();
      if (!isConnected) {
        setState(() {
          _error = 'No micro:bit found. Please:\n1. Connect micro:bit via USB cable\n2. Wait for it to appear as MICROBIT drive\n3. Try scanning again';
        });
        return;
      }
      
      // Lấy danh sách thiết bị USB
      final devices = await _usbService.getAvailableDevices();
      
      if (mounted) {
        _showDeviceSelectionDialog(devices);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to scan for USB devices: $e';
      });
    }
  }

  void _showDeviceSelectionDialog(List<Map<String, dynamic>> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select USB Device'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: devices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.usb_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No micro:bit found'),
                      SizedBox(height: 8),
                      Text('Please connect micro:bit via USB cable'),
                      Text('and wait for MICROBIT drive to appear'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.usb,
                        color: Colors.blue,
                      ),
                      title: Text(device['deviceName'] as String),
                      subtitle: Text('Path: ${device['path']}'),
                      onTap: () {
                        setState(() {
                          _selectedDevice = device;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _scanForDevices();
            },
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pythonController.dispose();
    _usbService.dispose();
    UniversalHexService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Hex Builder'),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Python Code Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Python Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pythonController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Enter your Python code here...\nExample:\ndisplay.scroll("Hello World")',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Build Button
            ElevatedButton.icon(
              onPressed: _isBuilding ? null : _buildUniversalHex,
              icon: _isBuilding 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build),
              label: Text(_isBuilding ? 'Building...' : 'Build Universal Hex'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ba4a),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Universal Hex Info
            if (_universalHex != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Universal Hex Built Successfully!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Size: ${(_estimatedSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                      Text('Lines: ${_universalHex!.split('\n').length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Device Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'USB Device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDevice?['deviceName'] ?? 'No device selected',
                            style: TextStyle(
                              color: _selectedDevice != null 
                                ? Colors.green 
                                : Colors.grey,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _scanForDevices,
                          icon: const Icon(Icons.usb),
                          label: const Text('Scan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Flash Button
            ElevatedButton.icon(
              onPressed: (_isFlashing || _universalHex == null || _selectedDevice == null) 
                ? null 
                : _flashHex,
              icon: _isFlashing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flash_on),
              label: Text(_isFlashing ? 'Flashing...' : 'Flash to micro:bit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Error Display
            if (_error != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
