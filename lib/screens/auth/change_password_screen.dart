import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
      title: 'auth.changePassword.title'.tr(),
      alignment: Alignment.center,
      gradientColors: const [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
      child: SectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _currentPassController,
                label: 'auth.changePassword.current'.tr(),
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (v) => (v == null || v.isEmpty) ? 'auth.changePassword.currentRequired'.tr() : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newPassController,
                label: 'auth.changePassword.new'.tr(),
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'auth.changePassword.newRequired'.tr();
                  if (v.length < 6) return 'auth.min6'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmNewPassController,
                label: 'auth.changePassword.confirm'.tr(),
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (v) => v != _newPassController.text ? 'auth.changePassword.notMatch'.tr() : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17a64b),
                    foregroundColor: const Color(0xFF2D3748),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                      : Text('auth.changePassword.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
