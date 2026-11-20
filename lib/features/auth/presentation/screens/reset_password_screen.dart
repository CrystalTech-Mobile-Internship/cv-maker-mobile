import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/i18n/app_language.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    final result = await controller.updatePassword(
      password: _passwordController.text,
      confirmation: _confirmationController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess
            ? null
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (!result.isSuccess) return;
    await controller.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final hasRecoverySession = ref.watch(currentAuthUserProvider) != null;
    if (!hasRecoverySession) return const _MissingRecoverySession();
    return Scaffold(
      appBar: AppBar(
        leading: homeFallbackLeading(context, fallback: '/login'),
        title: Text(tr('Đặt mật khẩu mới', 'Set a new password')),
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
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.password_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          tr(
                            'Bảo vệ tài khoản của bạn',
                            'Keep your account safe',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'Mật khẩu mới cần ít nhất 8 ký tự.',
                            'The new password needs at least 8 characters.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: tr('Mật khẩu mới', 'New password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmationController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => isLoading ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: tr(
                              'Nhập lại mật khẩu mới',
                              'Repeat new password',
                            ),
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  tr('Cập nhật mật khẩu', 'Update password'),
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
      ),
    );
  }
}

/// Shown when the screen is opened without a recovery session, e.g. the
/// email link expired or was opened in a different browser.
class _MissingRecoverySession extends StatelessWidget {
  const _MissingRecoverySession();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: homeFallbackLeading(context, fallback: '/login'),
        title: Text(tr('Đặt mật khẩu mới', 'Set a new password')),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_off_rounded, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Liên kết không còn hiệu lực',
                      'This link no longer works',
                    ),
                    key: ValueKey('reset-missing-session'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'Liên kết có thể đã hết hạn hoặc được mở trên trình duyệt khác. '
                          'Hãy gửi lại liên kết mới.',
                      'The link may have expired or been opened in another browser. Please request a new one.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(tr('Gửi lại liên kết', 'Resend link')),
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
