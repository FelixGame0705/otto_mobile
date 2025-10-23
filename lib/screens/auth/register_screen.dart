import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String? _agreeToTermsError;

  @override
  void dispose() {
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
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (result.isSuccess) {
            showSuccessToast(context, 'auth.register.success'.tr());
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          } else {
            showErrorToast(context, result.message ?? 'auth.register.failed'.tr());
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) showErrorToast(context, 'auth.networkError'.tr(args: [e.toString()]));
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
      title: 'auth.register.title'.tr(),
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
              Text('auth.register.heading'.tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 8),
              Text('auth.register.subheading'.tr(), style: const TextStyle(fontSize: 16, color: Color(0xFF718096))),
              const SizedBox(height: 24),


              AppTextField(
                controller: _emailController,
                label: 'auth.email'.tr(),
                hint: 'auth.enterEmail'.tr(),
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'auth.enterEmail'.tr();
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) return 'auth.emailInvalid'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordController,
                label: 'auth.password'.tr(),
                hint: 'auth.enterPassword'.tr(),
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'auth.enterPassword'.tr();
                  if (value.length < 6) return 'auth.min6'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmPasswordController,
                label: 'auth.confirmPassword'.tr(),
                hint: 'auth.confirmPassword.hint'.tr(),
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'auth.confirmPassword.hint'.tr();
                  if (value != _passwordController.text) return 'auth.passwordNotMatch'.tr();
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
                  Expanded(child: Text('auth.agreeTerms'.tr(), style: const TextStyle(color: Color(0xFF718096)))),
                  
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
                      : Text('auth.register.title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('auth.haveAccount'.tr() + ' ', style: const TextStyle(color: Color(0xFF718096))),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: Text('auth.login'.tr(), style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
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
