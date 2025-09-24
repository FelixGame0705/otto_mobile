import 'package:flutter/material.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/widgets/common/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmNewPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmNewPassController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    final res = await AuthService.changePassword(
      currentPassword: _currentPassController.text,
      newPassword: _newPassController.text,
    );
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? (res.isSuccess ? 'Đổi mật khẩu thành công' : 'Đổi mật khẩu thất bại')),
        backgroundColor: res.isSuccess ? Colors.green : Colors.red,
      ),
    );
    if (res.isSuccess && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Đổi mật khẩu',
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: SectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _currentPassController,
                label: 'Mật khẩu hiện tại',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newPassController,
                label: 'Mật khẩu mới',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                  if (v.length < 6) return 'Ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmNewPassController,
                label: 'Xác nhận mật khẩu mới',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (v) => v != _newPassController.text ? 'Không khớp' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDFCF2),
                    foregroundColor: const Color(0xFF2D3748),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                      : const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
