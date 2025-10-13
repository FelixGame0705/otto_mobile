import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class DetectCaptureScreen extends StatefulWidget {
  final bool asDialog;
  const DetectCaptureScreen({super.key, this.asDialog = false});

  @override
  State<DetectCaptureScreen> createState() => _DetectCaptureScreenState();
}

class _DetectCaptureScreenState extends State<DetectCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  dynamic _resultJson;
  String? _error;

  static const String _endpoint =
      'https://otto-detect.felixtien.dev/detect?min_thresh=0.5';

  Future<void> _pickFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _resultJson = null;
        _error = null;
      });
      await _upload();
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _resultJson = null;
        _error = null;
      });
      await _upload();
    }
  }

  Future<void> _upload() async {
    final image = _selectedImage;
    if (image == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(_endpoint);
      final request = http.MultipartRequest('POST', uri)
        ..headers['accept'] = 'application/json'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            contentType: MediaType('image', _guessMimeSubtype(image.path)),
          ),
        );

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = json.decode(resp.body);
        setState(() {
          _resultJson = decoded;
        });
        if (widget.asDialog) {
          final detections = (decoded['detections'] as List?)
                  ?.map((e) => (e as Map).cast<String, dynamic>())
                  .toList() ??
              <Map<String, dynamic>>[];
          if (mounted) {
            Navigator.of(context).pop(detections);
          }
          return;
        }
      } else {
        setState(() {
          _error = 'HTTP ${resp.statusCode}: ${resp.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _guessMimeSubtype(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    return 'jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isLandscape = orientation == Orientation.landscape;
                final bool useTwoPane = isLandscape && constraints.maxWidth >= 700;

                final loadingBar = _isLoading
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink();

                if (useTwoPane) {
                  // Side-by-side layout for large landscape screens
                  return Column(
                    children: [
                      loadingBar,
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildImagePreviewBox(),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildResultCard(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Stacked layout (portrait or small landscape)
                final double imageMaxHeight = constraints.maxHeight * 0.35;
                return Column(
                  children: [
                    loadingBar,
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: imageMaxHeight.clamp(160, 360),
                          minHeight: 120,
                        ),
                        child: _buildImagePreviewBox(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _buildResultCard(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
    );

    if (widget.asDialog) {
      return Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Detect from Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  tooltip: 'Camera',
                  color: Colors.white,
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.photo_camera),
                ),
                IconButton(
                  tooltip: 'Gallery',
                  color: Colors.white,
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                ),
                IconButton(
                  tooltip: 'Close',
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detect from Image'),
        actions: [
          IconButton(
            tooltip: 'Camera',
            icon: const Icon(Icons.photo_camera),
            onPressed: _pickFromCamera,
          ),
          IconButton(
            tooltip: 'Gallery',
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFromCamera,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture'),
      ),
    );
  }

  Widget _buildImagePreviewBox() {
    if (_selectedImage == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No image selected'),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_selectedImage!.path),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildResult(),
    );
  }

  Widget _buildResult() {
    if (_error != null) {
      return SingleChildScrollView(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_resultJson == null) {
      return const Center(
        child: Text('Choose an image to start detection.'),
      );
    }
    // Pretty print detections
    final detections = (_resultJson['detections'] as List?) ?? [];
    return ListView.separated(
      itemCount: detections.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = detections[index] as Map<String, dynamic>;
        final className = item['class_name']?.toString() ?? '';
        final value = item['value'];
        final actions = (item['actions'] as List?)?.cast<Map<String, dynamic>>();
        return ListTile(
          leading: const Icon(Icons.label_important_outline),
          title: Text(className),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value != null) Text('value: $value'),
              if (actions != null && actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: actions
                        .map((a) => Text('- ${a['class_name']}: ${a['value'] ?? ''}'))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

