import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class UsbService {
  bool _isConnected = false;
  String? _microbitPath;
  static const MethodChannel _usbChannel = MethodChannel('com.otto.ottobit/usb');

  bool get isConnected => _isConnected;
  String? get microbitPath => _microbitPath;

  Future<List<Map<String, dynamic>>> getAvailableDevices() async {
    try {
      // Request permissions on Android
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }
      
      final microbitDevices = <Map<String, dynamic>>[];

      // Android: hỏi trực tiếp danh sách USB từ native qua UsbManager
      if (Platform.isAndroid) {
        try {
          final nativeDevices = await _usbChannel.invokeMethod<List<dynamic>>('listUsbDevices');
          if (nativeDevices != null) {
            for (final d in nativeDevices) {
              if (d is Map) {
                final map = d.map((key, value) => MapEntry(key.toString(), value));
                final name = (map['productName'] ?? map['deviceName'] ?? 'USB Device').toString();
                microbitDevices.add({
                  'deviceName': name,
                  'path': '',
                  'native': map,
                });
              }
            }
          }
          print('Native USB devices found: ${microbitDevices.length}');
        } catch (e) {
          print('Error invoking native listUsbDevices: $e');
        }
      }
      
      // Kiểm tra các ổ đĩa có thể chứa micro:bit
      final drives = await _getAvailableDrives();
      print('Found ${drives.length} drives to check');
      
      for (final drive in drives) {
        print('Checking drive: ${drive.path}');
        
        // Kiểm tra thư mục MICROBIT (Windows)
        final microbitPath = '${drive.path}MICROBIT';
        if (await Directory(microbitPath).exists()) {
          print('Found micro:bit at: $microbitPath');
          microbitDevices.add({
            'deviceName': 'micro:bit',
            'path': microbitPath,
            'drive': drive.path,
          });
        }
        
        // Kiểm tra các thư mục con có thể chứa micro:bit
        try {
          final contents = await drive.list().toList();
          print('Found ${contents.length} items in drive ${drive.path}');
          
          for (final entity in contents) {
            if (entity is Directory) {
              final dirName = entity.path.split(Platform.isWindows ? '\\' : '/').last.toUpperCase();
              final dirNameLower = dirName.toLowerCase();
              
              // Debug: in tên thư mục để kiểm tra
              print('Checking directory: "$dirName" (lowercase: "$dirNameLower")');
              
              // Kiểm tra các tên thư mục có thể chứa micro:bit
              bool isUsbDevice = dirName.contains('MICROBIT') || 
                  dirName.contains('MICRO') ||
                  dirNameLower.contains('bộ nhớ usb') ||
                  dirNameLower.contains('bộ nhớ usb 1') ||
                  dirNameLower.contains('bộ nhớ usb 2') ||
                  dirNameLower.contains('bộ nhớ usb 3') ||
                  dirNameLower.contains('usb storage') ||
                  dirNameLower.contains('external storage') ||
                  dirNameLower.contains('usb1') ||
                  dirNameLower.contains('usb 1') ||
                  dirNameLower.contains('usb 2') ||
                  dirNameLower.contains('usb 3') ||
                  dirNameLower.contains('usb drive') ||
                  dirNameLower.contains('usb device') ||
                  dirNameLower.contains('removable') ||
                  dirNameLower.contains('mass storage');
              
              if (isUsbDevice) {
                print('Found potential micro:bit directory: ${entity.path}');
                microbitDevices.add({
                  'deviceName': 'micro:bit (${dirName})',
                  'path': entity.path,
                  'drive': drive.path,
                });
              } else {
                // Nếu không match với filter, vẫn thêm vào để debug
                print('Directory does not match USB filter: ${entity.path}');
              }
            }
          }
        } catch (e) {
          print('Error reading drive ${drive.path}: $e');
        }
      }
      
      // Nếu không tìm thấy qua file system, thử MediaStore và test directory
      if (microbitDevices.isEmpty && Platform.isAndroid) {
        print('No devices found via file system, trying MediaStore...');
        final mediaStoreDevices = await getUsbDevicesFromMediaStore();
        microbitDevices.addAll(mediaStoreDevices);
        
        // Thử liệt kê tất cả thư mục mà không filter
        await _listAllDirectories(microbitDevices);
        
        // Thêm test USB directory
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final testUsbDir = Directory('${appDir.path}/test_usb');
          if (await testUsbDir.exists()) {
            microbitDevices.add({
              'deviceName': 'micro:bit (Test)',
              'path': testUsbDir.path,
              'drive': appDir.path,
            });
            print('Added test USB directory: ${testUsbDir.path}');
          }
        } catch (e) {
          print('Error adding test USB directory: $e');
        }
      }
      
      print('Total micro:bit devices found: ${microbitDevices.length}');
      return microbitDevices;
    } catch (e) {
      print('Error getting micro:bit devices: $e');
      return [];
    }
  }

  Future<List<Directory>> _getAvailableDrives() async {
    final drives = <Directory>[];
    
    if (Platform.isWindows) {
      // Windows drives (C:, D:, E:, etc.)
      for (int i = 65; i <= 90; i++) {
        final driveLetter = String.fromCharCode(i);
        final drivePath = '$driveLetter:\\';
        final drive = Directory(drivePath);
        
        try {
          if (await drive.exists()) {
            // Kiểm tra xem có thể đọc được không
            await drive.list().first;
            drives.add(drive);
          }
        } catch (e) {
          // Bỏ qua các ổ đĩa không thể truy cập
          print('Cannot access drive $drivePath: $e');
        }
      }
    } else if (Platform.isAndroid) {
      // Android: kiểm tra các thư mục USB storage phổ biến
      final androidPaths = [
        '/storage/usbotg',
        '/storage/usb1',
        '/storage/usb2',
        '/storage/usb3',
        '/mnt/usb',
        '/mnt/usbotg',
        '/mnt/usb1',
        '/mnt/usb2',
        '/mnt/usb3',
        '/storage/external_storage',
        '/storage/emulated/0/usb',
        '/storage/emulated/0/usbotg',
        '/sdcard/usb',
        '/sdcard/usbotg',
        '/sdcard/usb1',
        '/storage/sdcard0/usb',
        '/storage/sdcard0/usbotg',
        '/storage/sdcard0/usb1',
        '/storage/emulated/0/Android/data/com.otto.ottobit/files/usb',
        '/storage/emulated/0/Android/data/com.otto.ottobit/files/usbotg',
      ];
      
      print('Checking Android USB paths...');
      for (final path in androidPaths) {
        final drive = Directory(path);
        try {
          if (await drive.exists()) {
            print('Path exists: $path');
            try {
              await drive.list().first;
              drives.add(drive);
              print('Found Android USB drive: $path');
            } catch (e) {
              print('Cannot list contents of $path: $e');
            }
          } else {
            print('Path does not exist: $path');
          }
        } catch (e) {
          print('Error checking Android drive $path: $e');
        }
      }
      
      // Thử kiểm tra thư mục gốc storage
      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          print('Checking /storage directory...');
          final contents = await storageDir.list().toList();
          for (final entity in contents) {
            if (entity is Directory) {
              final dirName = entity.path.split('/').last;
              print('Found in /storage: $dirName');
              if (dirName.toLowerCase().contains('usb') || 
                  dirName.toLowerCase().contains('otg') ||
                  dirName.toLowerCase().contains('external')) {
                try {
                  await entity.list().first;
                  drives.add(entity);
                  print('Added USB drive: ${entity.path}');
                } catch (e) {
                  print('Cannot access ${entity.path}: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error checking /storage: $e');
      }
    }
    
    return drives;
  }

  Future<bool> isMicrobitConnected() async {
    final devices = await getAvailableDevices();
    return devices.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUsbDevicesFromMediaStore() async {
    // Thử tìm USB devices thông qua MediaStore (Android)
    final usbDevices = <Map<String, dynamic>>[];
    
    try {
      // Kiểm tra thư mục Downloads có thể chứa file từ USB
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        print('Checking Downloads directory for USB files...');
        final files = await downloadsDir.list().toList();
        for (final file in files) {
          if (file is File) {
            final fileName = file.path.split('/').last.toLowerCase();
            if (fileName.contains('microbit') || fileName.contains('micro') || fileName.endsWith('.hex')) {
              usbDevices.add({
                'deviceName': 'micro:bit (Download)',
                'path': file.parent.path,
                'file': file.path,
              });
            }
          }
        }
      }
      
      // Tạo thư mục test USB để demo
      await _createTestUsbDirectory();
      
    } catch (e) {
      print('Error checking MediaStore: $e');
    }
    
    return usbDevices;
  }

  Future<void> _createTestUsbDirectory() async {
    try {
      // Tạo thư mục test trong app directory
      final appDir = await getApplicationDocumentsDirectory();
      final testUsbDir = Directory('${appDir.path}/test_usb');
      
      if (!await testUsbDir.exists()) {
        await testUsbDir.create(recursive: true);
        print('Created test USB directory: ${testUsbDir.path}');
        
        // Tạo file test
        final testFile = File('${testUsbDir.path}/test.txt');
        await testFile.writeAsString('Test USB directory for micro:bit');
      }
    } catch (e) {
      print('Error creating test USB directory: $e');
    }
  }

  Future<void> _listAllDirectories(List<Map<String, dynamic>> microbitDevices) async {
    try {
      print('Listing all directories without filter...');
      
      // Thử các đường dẫn phổ biến trên Android
      final commonPaths = [
        '/storage',
        '/mnt',
        '/sdcard',
        '/storage/emulated/0',
      ];
      
      for (final basePath in commonPaths) {
        try {
          final baseDir = Directory(basePath);
          if (await baseDir.exists()) {
            print('Scanning $basePath...');
            final contents = await baseDir.list().toList();
            
            for (final entity in contents) {
              if (entity is Directory) {
                final dirName = entity.path.split('/').last;
                print('Found directory: $dirName at ${entity.path}');
                
                // Thêm tất cả thư mục để debug
                microbitDevices.add({
                  'deviceName': 'Directory: $dirName',
                  'path': entity.path,
                  'drive': basePath,
                });
              }
            }
          }
        } catch (e) {
          print('Error scanning $basePath: $e');
        }
      }
    } catch (e) {
      print('Error listing all directories: $e');
    }
  }

  Future<bool> connectToDevice(Map<String, dynamic> device) async {
    try {
      final selectedPath = (device['path'] as String?) ?? '';
      // Allow connect even if path is empty (native USB listing). We'll ask user to pick a folder on flash.
      if (selectedPath.isNotEmpty && await Directory(selectedPath).exists()) {
        _microbitPath = selectedPath;
      } else {
        _microbitPath = null;
      }
      _isConnected = true;
      print('Connected to micro:bit. Path: ${_microbitPath ?? '(none via native)'}');
      return true;
    } catch (e) {
      print('Error connecting to micro:bit: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    _microbitPath = null;
    _isConnected = false;
    print('Disconnected from micro:bit');
  }

  Future<bool> flashHexFile(String hexContent) async {
    if (!_isConnected) {
      throw Exception('Not connected to micro:bit');
    }

    try {
      // Ensure we have a writable target directory. If missing, ask user to pick folder (e.g., "Bộ nhớ USB 1").
      var targetDirPath = _microbitPath;
      if (targetDirPath == null || !await Directory(targetDirPath).exists()) {
        if (Platform.isAndroid) {
          print('No writable path set. Prompting user to pick USB directory...');
          final picked = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Chọn thư mục MICROBIT (Bộ nhớ USB 1)');
          if (picked == null) {
            throw Exception('USB directory not selected');
          }
          targetDirPath = picked;
          _microbitPath = picked;
        } else {
          throw Exception('Writable USB path not available');
        }
      }

      // Step 1: Write to a temporary file in app storage
      final tmpDir = await getTemporaryDirectory();
      final tmpHexPath = '${tmpDir.path}${Platform.isWindows ? '\\' : '/'}firmware.hex';
      final tmpHexFile = File(tmpHexPath);
      await tmpHexFile.writeAsString(hexContent);
      print('Temporary hex built at: $tmpHexPath');

      // Step 2: On Android, use native SAF createDocument flow if direct copy may fail
      if (Platform.isAndroid) {
        print('Attempting SAF createDocument write for firmware.hex');
        final bytes = await tmpHexFile.readAsBytes();
        final ok = await _safCreateAndWrite('firmware.hex', bytes);
        if (!ok) {
          // Fallback to best-effort copy
          final separator = Platform.isWindows ? '\\' : '/';
          final targetHexPath = '$targetDirPath${separator}firmware.hex';
          await tmpHexFile.copy(targetHexPath);
          print('Hex file copied to micro:bit (fallback): $targetHexPath');
        }
      } else {
        final separator = Platform.isWindows ? '\\' : '/';
        final targetHexPath = '$targetDirPath${separator}firmware.hex';
        await tmpHexFile.copy(targetHexPath);
        print('Hex file copied to micro:bit: $targetHexPath');
      }
      print('micro:bit will automatically flash the new firmware');
      
      // Đợi một chút để micro:bit xử lý
      await Future.delayed(const Duration(seconds: 2));
      
      return true;
    } catch (e) {
      print('Error flashing hex file: $e');
      return false;
    }
  }

  Future<bool> _safCreateAndWrite(String fileName, List<int> bytes) async {
    try {
      final ok = await _usbChannel.invokeMethod<bool>('createDocumentAndWrite', {
        'fileName': fileName,
        'bytes': Uint8List.fromList(bytes),
      });
      return ok == true;
    } catch (e) {
      print('SAF write failed: $e');
      return false;
    }
  }

  Future<String?> readResponse({Duration timeout = const Duration(seconds: 5)}) async {
    // micro:bit không hỗ trợ serial communication qua USB mass storage
    return null;
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      print('Requesting Android storage permissions...');
      
      // Kiểm tra Android version
      if (Platform.isAndroid) {
        // Android 11+ cần MANAGE_EXTERNAL_STORAGE
        final manageStorageStatus = await Permission.manageExternalStorage.status;
        if (manageStorageStatus.isDenied) {
          print('Requesting MANAGE_EXTERNAL_STORAGE permission...');
          await Permission.manageExternalStorage.request();
          // Nếu vẫn denied, mở trang cài đặt All files access
          final after = await Permission.manageExternalStorage.status;
          if (after.isDenied) {
            print('Opening All files access settings...');
            try { await _usbChannel.invokeMethod('openAllFilesAccessSettings'); } catch (_) {}
          }
        }
        
        // Android 10 và thấp hơn cần READ_EXTERNAL_STORAGE
        final readStorageStatus = await Permission.storage.status;
        if (readStorageStatus.isDenied) {
          print('Requesting READ_EXTERNAL_STORAGE permission...');
          await Permission.storage.request();
        }
        
        // Kiểm tra quyền sau khi request
        final finalManageStatus = await Permission.manageExternalStorage.status;
        final finalReadStatus = await Permission.storage.status;
        
        print('Final permissions:');
        print('MANAGE_EXTERNAL_STORAGE: $finalManageStatus');
        print('READ_EXTERNAL_STORAGE: $finalReadStatus');
        
        if (finalManageStatus.isDenied && finalReadStatus.isDenied) {
          print('WARNING: Both storage permissions denied!');
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  void dispose() {
    disconnect();
  }
}
