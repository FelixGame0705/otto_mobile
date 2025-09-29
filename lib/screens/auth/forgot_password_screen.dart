import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await AuthService.forgotPassword(
          _emailController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (result.isSuccess) {
            setState(() {
              _isEmailSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? 'Email đặt lại mật khẩu đã được gửi!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message ?? 'Gửi email thất bại'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleBackToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'auth.forgotPassword'.tr(),
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: SectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: Image.asset(
                  'assets/images/LogoOttobit.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text('auth.forgotPassword'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 8),
              Text('auth.forgot.desc'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF718096))),
              const SizedBox(height: 20),

              if (!_isEmailSent) ...[
                AppTextField(
                  controller: _emailController,
                  label: 'auth.email'.tr(),
                  hint: 'auth.enterEmail'.tr(),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'auth.enterEmail'.tr();
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'auth.emailInvalid'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ba4a),
                      foregroundColor: const Color(0xFF2D3748),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                        : Text('auth.forgot.send'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF68D391)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF38A169), size: 40),
                      const SizedBox(height: 8),
                      Text('auth.forgot.sent'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38A169))),
                      const SizedBox(height: 4),
                      Text('auth.forgot.check'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF4A5568))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEmailSent = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D3748),
                      side: const BorderSide(color: Color(0xFF2D3748)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('auth.forgot.resend'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _handleBackToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D3748),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('auth.backToLogin'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
