import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/auth_callback_parser.dart';
import '../../../../core/constants/env_constants.dart';
import '../providers/auth_providers.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/i18n/language_menu_button.dart';
import '../../../../core/i18n/app_language.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.linkError,
    this.showRecoveryCode,
  });

  /// Error code from a failed email link (e.g. `otp_expired`).
  final String? linkError;

  /// Overrides the configuration flag (used by tests).
  final bool? showRecoveryCode;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _sent = false;
  int _cooldown = 0;
  Timer? _timer;

  /// Prevents repeated sends while the email service has a low hourly limit.
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _toast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() => _sent = result.isSuccess);
    if (result.isSuccess) _startCooldown();
    _toast(result.message, isError: !result.isSuccess);
  }

  Future<void> _verifyCode() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .verifyRecoveryCode(
          email: _emailController.text,
          code: _codeController.text,
        );
    if (!mounted) return;
    _toast(result.message, isError: !result.isSuccess);
    if (result.isSuccess) context.go('/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final showCode =
        widget.showRecoveryCode ?? EnvConstants.recoveryCodeInEmail;
    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageMenuButton(), SizedBox(width: 8)],
        leading: homeFallbackLeading(context, fallback: '/login'),
        title: Text(tr('Quên mật khẩu', 'Forgot password')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.linkError != null) ...[
                        Container(
                          key: const ValueKey('reset-link-error'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.amberSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            describeAuthLinkError(widget.linkError),
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Icon(Icons.mark_email_read_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _sent
                            ? tr('Kiểm tra hộp thư của bạn', 'Check your inbox')
                            : tr(
                                'Nhận liên kết đặt lại mật khẩu',
                                'Get a password reset link',
                              ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _sent
                            ? (showCode
                                  ? tr(
                                      'Mở liên kết trong email trên chính thiết bị và trình duyệt này, '
                                          'hoặc nhập mã khôi phục trong email ở bên dưới.',
                                      'Open the link in the email on this same device and browser, or enter the reset code from the email below.',
                                    )
                                  : tr(
                                      'Mở liên kết trong email trên chính thiết bị và trình duyệt này '
                                          'để đặt mật khẩu mới.',
                                      'Open the link in the email on this same device and browser to set a new password.',
                                    ))
                            : tr(
                                'Nhập email tài khoản. CV lưu trên thiết bị sẽ không bị thay đổi.',
                                'Enter your account email. CVs on this device will not change.',
                              ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        key: const ValueKey('reset-email'),
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            isLoading || _sent ? null : _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: isLoading || _cooldown > 0 ? null : _submit,
                        icon: isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _cooldown > 0
                              ? tr(
                                  'Gửi lại sau ${_cooldown}s',
                                  'Resend in ${_cooldown}s',
                                )
                              : _sent
                              ? tr('Gửi lại liên kết', 'Resend link')
                              : tr('Gửi liên kết', 'Send link'),
                        ),
                      ),
                      if (showCode) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          tr(
                            'Đã có mã khôi phục trong email?',
                            'Got a reset code in the email?',
                          ),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('reset-code'),
                          controller: _codeController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: tr('Mã khôi phục', 'Reset code'),
                            hintText: tr('Ví dụ: 123456', 'e.g. 123456'),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const ValueKey('reset-verify-code'),
                          onPressed: isLoading ? null : _verifyCode,
                          child: Text(tr('Xác nhận mã', 'Confirm code')),
                        ),
                      ],
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          tr('Quay lại đăng nhập', 'Back to sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
