import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/widgets/common/language_dropdown.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/widgets/common/app_text_field.dart';
import 'package:ottobit/widgets/ui/notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/jwt_token_manager.dart';
import 'package:ottobit/models/user_model.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '230205957347-92orekvvv41o7dkis4431883v35ei9s5.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý lỗi PlatformException từ Google Sign-In
  String _handleGoogleSignInError(dynamic error) {
    if (error is PlatformException) {
      final code = error.code;
      final message = error.message ?? '';
      
      switch (code) {
        case 'sign_in_canceled':
        case 'SIGN_IN_CANCELLED':
          return 'auth.googleLoginCanceled'.tr();
        case 'sign_in_failed':
        case 'SIGN_IN_FAILED':
          return 'auth.googleSignInFailed'.tr();
        case 'network_error':
        case 'SIGN_IN_NETWORK_ERROR':
          return 'auth.googleNetworkError'.tr();
        case 'sign_in_required':
        case 'SIGN_IN_REQUIRED':
          return 'auth.googleSignInRequired'.tr();
        case 'internal_error':
          return 'auth.googleInternalError'.tr();
        case 'invalid_account':
        case 'INVALID_ACCOUNT':
          return 'auth.googleInvalidAccount'.tr();
        case 'account_disabled':
          return 'auth.googleAccountDisabled'.tr();
        case 'DEVELOPER_ERROR':
          return 'auth.googleDeveloperError'.tr();
        default:
          // Nếu có message từ PlatformException, sử dụng nó
          if (message.isNotEmpty) {
            return message;
          }
          return 'auth.googleSignInFailed'.tr();
      }
    }
    
    // Xử lý các loại lỗi khác
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
      return 'auth.googleLoginCanceled'.tr();
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'auth.googleNetworkError'.tr();
    }
    if (errorStr.contains('sign_in_failed') || errorStr.contains('sign_in_error')) {
      return 'auth.googleSignInFailed'.tr();
    }
    
    return 'auth.googleSignInFailed'.tr();
  }

  Future<void> _handleGoogleLogin() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Sign out trước để luôn hiển thị dialog chọn tài khoản
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Log nhưng không báo lỗi khi sign out
        debugPrint('Google Sign-Out error (ignored): $e');
      }
      
      // Sign in - sẽ luôn hiển thị dialog chọn tài khoản
      GoogleSignInAccount? account;
      try {
        account = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          final errorMsg = _handleGoogleSignInError(e);
          showErrorToast(context, errorMsg);
        }
        return;
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          final errorMsg = _handleGoogleSignInError(e);
          showErrorToast(context, errorMsg);
        }
        return;
      }
      
      if (account == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          showErrorToast(context, 'auth.googleLoginCanceled'.tr());
        }
        return;
      }
      
      // Lấy authentication
      GoogleSignInAuthentication? auth;
      try {
        auth = await account.authentication;
      } on PlatformException catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          final errorMsg = _handleGoogleSignInError(e);
          showErrorToast(context, errorMsg);
        }
        return;
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          showErrorToast(context, 'Lỗi khi lấy thông tin xác thực Google: ${_handleGoogleSignInError(e)}');
        }
        return;
      }
      
      final idtoken = auth.idToken;
      if (idtoken == null || idtoken.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          showErrorToast(context, 'auth.googleIdTokenError'.tr());
        }
        return;
      }

      // Gọi API đăng nhập với backend
      final response = await AuthService.loginWithGoogle(idtoken);

      // Handle response: persist tokens, user, then navigate
      try {
        final message = (response['message'] ?? '').toString();
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null) {
          setState(() => _isLoading = false);
        if (mounted) {
          showErrorToast(
            context,
            message.isNotEmpty ? message : 'auth.googleLoginFailed'.tr(),
          );
        }
          return;
        }

        final userMap = (data['user'] ?? {}) as Map<String, dynamic>;
        final tokens = (data['tokens'] ?? {}) as Map<String, dynamic>;
        final accessToken = (tokens['accessToken'] ?? '').toString();
        final refreshToken = (tokens['refreshToken'] ?? '').toString();
        final expiresAtUtcStr = (tokens['expiresAtUtc'] ?? '').toString();

        if (accessToken.isEmpty) {
          setState(() => _isLoading = false);
          if (mounted) {
            showErrorToast(context, 'auth.googleLoginFailed'.tr());
          }
          return;
        }

        await StorageService.saveToken(accessToken);
        await StorageService.saveRefreshToken(refreshToken);

        DateTime? expiryTime;
        if (expiresAtUtcStr.isNotEmpty) {
          try {
            expiryTime = DateTime.parse(expiresAtUtcStr).toLocal();
          } catch (_) {}
        }
        if (expiryTime == null) {
          final payload = JwtTokenManager.getTokenPayload(accessToken);
          final exp = payload != null ? payload['exp'] : null;
          if (exp != null) {
            expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          }
        }
        if (expiryTime != null) {
          await StorageService.saveTokenExpiry(expiryTime);
        }

        final user = UserModel(
          id: (userMap['userId'] ?? userMap['id'] ?? '').toString(),
          fullName: (userMap['fullName'] ?? account.displayName ?? '').toString(),
          email: (userMap['email'] ?? account.email).toString(),
          phone: (userMap['phone'] ?? '').toString(),
          avatar: (userMap['avatar'] ?? '')?.toString(),
          createdAt: DateTime.now(),
          isActive: true,
        );
        await StorageService.saveUser(user);

        setState(() => _isLoading = false);
        if (mounted) {
          showSuccessToast(context, message.isNotEmpty ? message : 'Đăng nhập thành công!');
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          final errorMsg = e is PlatformException 
              ? _handleGoogleSignInError(e)
              : 'auth.googleAuthError'.tr();
          showErrorToast(context, errorMsg);
        }
      }
    } on PlatformException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMsg = _handleGoogleSignInError(e);
        showErrorToast(context, errorMsg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMsg = _handleGoogleSignInError(e);
        showErrorToast(context, errorMsg);
      }
    }
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
      alignment: Alignment.center,
      gradientColors: const [Color(0xFFEDFCF2), Color.fromARGB(255, 255, 255, 255)],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
              Text('auth.welcomeBack'.tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 8),
              Text('auth.loginToContinue'.tr(), style: const TextStyle(fontSize: 16, color: Color(0xFF718096))),
              const SizedBox(height: 8),
              // Language switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
      // Language dropdown with flags
      SizedBox(
        width: 240,
        child: LanguageDropdown(
          onLocaleChanged: (_) {},
        ),
      ),
                ],
              ),
              const SizedBox(height: 24),

              AppTextField(
                controller: _emailController,
                label: 'auth.email',
                hint: 'auth.enterEmail',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'auth.enterEmail'.tr();
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'auth.emailInvalid'.tr();
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
                label: 'auth.password',
                hint: 'auth.enterPassword',
                prefixIcon: Icons.lock_outlined,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'auth.enterPassword'.tr();
                  if (value.length < 6) return 'auth.min6'.tr();
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
                  child: Text('auth.forgotPassword'.tr(), style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
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
                      : Text('auth.login'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              // Google login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.login),
                  label: Text('auth.loginWithGoogle'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D3748),
                    side: const BorderSide(color: Color(0xFF2D3748)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('auth.noAccount'.tr() + ' ', style: const TextStyle(color: Color(0xFF718096))),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: Text('auth.registerNow'.tr(), style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
