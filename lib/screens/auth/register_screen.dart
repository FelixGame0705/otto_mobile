import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/widgets/common/app_text_field.dart';
import 'package:ottobit/widgets/ui/notifications.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String? _agreeToTermsError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isLoading = true;
        _agreeToTermsError = null;
      });

      try {
        final result = await AuthService.register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (result.isSuccess) {
            showSuccessToast(context, 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.');
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          } else {
            showErrorToast(context, result.message ?? 'Đăng ký thất bại');
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) showErrorToast(context, 'Lỗi kết nối: $e');
      }
    } 
    else if (!_agreeToTerms) {
      setState(() {
        _agreeToTermsError = 'Vui lòng đồng ý với điều khoản sử dụng';
      });
      //showErrorToast(context, 'Vui lòng đồng ý với điều khoản sử dụng');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Đăng ký',
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: SectionCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                child: Image.asset(
                  'assets/images/LogoOttobit.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFEDFCF2), borderRadius: BorderRadius.circular(40)),
                    child: const Icon(Icons.person_add, size: 40, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Điền thông tin để đăng ký',
                style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
              ),
              const SizedBox(height: 24),

              AppTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên đầy đủ',
                prefixIcon: Icons.person_outlined,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
                  if (value.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Nhập email của bạn',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) return 'Email không hợp lệ';
                  return null;
                },
              ),
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
              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                hint: 'Nhập lại mật khẩu',
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                  if (value != _passwordController.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (v) => setState(() {
                      _agreeToTerms = v ?? false;
                      if (_agreeToTerms) _agreeToTermsError = null;
                    }),
                    activeColor: const Color(0xFF00ba4a),
                  ),
                  const Expanded(
                    child: Text('Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật', style: TextStyle(color: Color(0xFF718096))),
                  ),
                  
                ],
              ),
              if (_agreeToTermsError != null && _agreeToTermsError!.isNotEmpty)
                const SizedBox(height: 6),
              if (_agreeToTermsError != null && _agreeToTermsError!.isNotEmpty)
                InlineErrorText(message: _agreeToTermsError!),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ba4a),
                    foregroundColor: const Color(0xFF2D3748),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black54)))
                      : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? ', style: TextStyle(color: Color(0xFF718096))),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
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
