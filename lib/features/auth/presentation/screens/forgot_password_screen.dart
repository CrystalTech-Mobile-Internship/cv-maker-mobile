import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/auth_callback_parser.dart';
import '../../../../core/constants/env_constants.dart';
import '../providers/auth_providers.dart';

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

  @override
  void dispose() {
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
      appBar: AppBar(title: const Text('Quên mật khẩu')),
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
                            ? 'Kiểm tra hộp thư của bạn'
                            : 'Nhận liên kết đặt lại mật khẩu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _sent
                            ? (showCode
                                  ? 'Mở liên kết trong email trên chính thiết bị và trình duyệt này, '
                                        'hoặc nhập mã khôi phục trong email ở bên dưới.'
                                  : 'Mở liên kết trong email trên chính thiết bị và trình duyệt này '
                                        'để đặt mật khẩu mới.')
                            : 'Nhập email tài khoản. CV lưu trên thiết bị sẽ không bị thay đổi.',
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
                        onPressed: isLoading ? null : _submit,
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
                          _sent ? 'Gửi lại liên kết' : 'Gửi liên kết',
                        ),
                      ),
                      if (showCode) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Đã có mã khôi phục trong email?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('reset-code'),
                          controller: _codeController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'Mã khôi phục',
                            hintText: 'Ví dụ: 123456',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const ValueKey('reset-verify-code'),
                          onPressed: isLoading ? null : _verifyCode,
                          child: const Text('Xác nhận mã'),
                        ),
                      ],
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Quay lại đăng nhập'),
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
