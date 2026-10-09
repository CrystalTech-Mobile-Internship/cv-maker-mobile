import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/env_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../app/theme.dart';
import '../../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = SupabaseService.client?.auth.onAuthStateChange.listen((
      state,
    ) {
      if (!mounted ||
          state.event != AuthChangeEvent.signedIn ||
          state.session == null) {
        return;
      }
      context.go('/home');
    });
    if (_authService.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (!EnvConstants.isSupabaseConfigured) {
      _showMessage('Hãy cấu hình Supabase trước khi đăng nhập Google.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final launched = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (!launched) {
        setState(() => _isLoading = false);
        _showMessage('Không thể mở màn hình đăng nhập Google.');
      }
      // On success, Supabase Flutter receives the deep link and the auth
      // listener above navigates to Home.
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(_friendlyAuthError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Không thể khởi động đăng nhập Google.');
    }
  }

  void _handleGuestLogin() {
    // Navigate straight to dashboard in guest / offline mode
    context.go('/home');
  }

  Future<void> _handleSupabaseAuth() async {
    if (!EnvConstants.isSupabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Supabase chưa được cấu hình key thực tế. Vui lòng chọn "Chế độ Khách / Offline" để trải nghiệm trước!',
          ),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      _showMessage('Vui lòng nhập email hợp lệ và mật khẩu ít nhất 6 ký tự.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = _isRegisterMode
          ? await _authService.signUp(email: email, password: password)
          : await _authService.signIn(email: email, password: password);

      if (!mounted) return;
      if (response.session == null) {
        setState(() => _isLoading = false);
        _showMessage(
          _isRegisterMode
              ? 'Đăng ký thành công. Hãy kiểm tra email để xác nhận tài khoản rồi đăng nhập.'
              : 'Tài khoản chưa có phiên đăng nhập. Hãy kiểm tra email xác nhận trong Supabase.',
        );
        return;
      }

      setState(() => _isLoading = false);
      context.go('/home');
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        'Không thể kết nối Supabase. Hãy kiểm tra mạng và cấu hình .env.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email chưa được xác nhận. Hãy kiểm tra hộp thư của bạn.';
    }
    if (message.contains('user already registered')) {
      return 'Email này đã được đăng ký. Hãy chuyển sang Đăng nhập.';
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo & Branding
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySlate,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      size: 40,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Login Card Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode
                              ? 'Tạo tài khoản'
                              : 'Đăng nhập tài khoản',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSupabaseAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isRegisterMode ? 'Đăng ký' : 'Đăng nhập'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Tiếp tục với Google'),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(
                                  () => _isRegisterMode = !_isRegisterMode,
                                ),
                          child: Text(
                            _isRegisterMode
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'HOẶC',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _handleGuestLogin,
                          icon: const Icon(
                            Icons.offline_bolt_outlined,
                            color: AppTheme.accentTeal,
                          ),
                          label: const Text('Trải nghiệm Offline (Khách)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cloud Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      EnvConstants.isSupabaseConfigured
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      size: 16,
                      color: EnvConstants.isSupabaseConfigured
                          ? AppTheme.successGreen
                          : AppTheme.warningAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      EnvConstants.isSupabaseConfigured
                          ? 'Supabase Cloud: Đã kết nối'
                          : 'Supabase Cloud: Đang đợi key (Chế độ Local)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
