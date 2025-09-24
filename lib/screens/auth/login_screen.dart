import 'package:flutter/material.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/services/auth_service.dart';
import 'package:otto_mobile/layout/app_scaffold.dart';
import 'package:otto_mobile/widgets/common/section_card.dart';
import 'package:otto_mobile/widgets/common/app_text_field.dart';
import 'package:otto_mobile/widgets/ui/notifications.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _emailError = null;
        _passwordError = null;
      });

      try {
        final result = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (result.isSuccess) {
            showSuccessToast(context, 'Đăng nhập thành công!');
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            final msg = (result.message ?? '').trim();
            bool handledInline = false;
            setState(() {
              final lower = msg.toLowerCase();
              if (lower.contains('email is not a valid') || lower.contains('email')) {
                _emailError = msg;
                handledInline = true;
              }
              if (lower.contains('invalid email or password')) {
                _passwordError = msg;
                handledInline = true;
              }
            });
            if (!handledInline) {
              showErrorToast(context, msg.isNotEmpty ? msg : 'Đăng nhập thất bại');
            }
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showErrorToast(context, 'Lỗi kết nối: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: Form(
        key: _formKey,
        child: SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Bo góc cho hình chữ nhật
                  child: Image.asset(
                    'assets/images/LogoOttobit.png',
                    fit: BoxFit.cover, // Hiển thị hình chữ nhật đầy đủ
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDFCF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security, size: 40, color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Chào mừng trở lại!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 8),
              const Text('Đăng nhập để tiếp tục', style: TextStyle(fontSize: 16, color: Color(0xFF718096))),
              const SizedBox(height: 24),

              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Nhập email của bạn',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email không hợp lệ';
                  return null;
                },
              ),
              if (_emailError != null && _emailError!.isNotEmpty)
                const SizedBox(height: 6),
              if (_emailError != null && _emailError!.isNotEmpty)
                InlineErrorText(message: _emailError!),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordController,
                label: 'Mật khẩu',
                hint: 'Nhập mật khẩu của bạn',
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              if (_passwordError != null && _passwordError!.isNotEmpty)
                const SizedBox(height: 6),
              if (_passwordError != null && _passwordError!.isNotEmpty)
                InlineErrorText(message: _passwordError!),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ba4a),
                    foregroundColor: const Color(0xFF2D3748),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black54)))
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: Color(0xFF718096))),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Đăng ký ngay', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
