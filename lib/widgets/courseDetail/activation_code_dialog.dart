import 'package:flutter/material.dart';
import 'package:ottobit/services/activation_code_service.dart';

class ActivationCodeDialog extends StatefulWidget {
  final String? courseTitle;
  final String? robotName;
  final VoidCallback? onCodeRedeemed;

  const ActivationCodeDialog({
    super.key,
    this.courseTitle,
    this.robotName,
    this.onCodeRedeemed,
  });

  @override
  State<ActivationCodeDialog> createState() => _ActivationCodeDialogState();
}

class _ActivationCodeDialogState extends State<ActivationCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  final ActivationCodeService _activationCodeService = ActivationCodeService();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã kích hoạt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRedeeming = true;
    });

    try {
      final response = await _activationCodeService.redeemCode(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
        widget.onCodeRedeemed?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kích hoạt mã: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.smart_toy,
                  color: Color(0xFF00ba4a),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kích hoạt Robot',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Nhập mã kích hoạt để sử dụng robot cho khóa học này',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            if (widget.courseTitle != null || widget.robotName != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.courseTitle != null) ...[
                      Text(
                        'Khóa học: ${widget.courseTitle}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (widget.robotName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Robot: ${widget.robotName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Activation Code Input
            Text(
              'Mã kích hoạt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Nhập mã kích hoạt robot',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  onPressed: _codeController.clear,
                  icon: const Icon(Icons.clear),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _redeemCode(),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isRedeeming ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isRedeeming ? null : _redeemCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ba4a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isRedeeming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Kích hoạt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
