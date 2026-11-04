import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../auth_redirect.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _showMessage(
        'Bạn cần đồng ý điều khoản để tạo tài khoản.',
        isError: true,
      );
      return;
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmation: _confirmationController.text,
        );
    if (!mounted) return;
    _showMessage(result.message, isError: !result.isSuccess);
    if (!result.isSuccess) return;
    if (result.requiresEmailConfirmation) {
      context.go(authEntryLocation('/login', widget.redirectPath));
    } else {
      context.go(safeAuthRedirect(widget.redirectPath) ?? '/home');
    }
  }

  Future<void> _signInWithGoogle() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (mounted && !result.isSuccess) {
      _showMessage(result.message, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final isConfigured = ref.watch(authRepositoryProvider).isConfigured;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () =>
              context.go(authEntryLocation('/login', widget.redirectPath)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Tạo tài khoản'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bắt đầu tạo CV chuyên nghiệp',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đồng bộ CV và tiếp tục chỉnh sửa trên thiết bị của bạn.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      const _LocalDataNotice(),
                      const SizedBox(height: 16),
                      _field(
                        controller: _nameController,
                        label: 'Họ và tên',
                        icon: Icons.person_outline_rounded,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.length < 2) {
                            return 'Vui lòng nhập họ và tên.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Email chưa đúng định dạng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        obscureText: _obscurePassword,
                        onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        validator: (value) => (value?.length ?? 0) < 8
                            ? 'Tối thiểu 8 ký tự.'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nên có chữ hoa, chữ thường và số.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        controller: _confirmationController,
                        label: 'Xác nhận mật khẩu',
                        obscureText: _obscureConfirmation,
                        onToggle: () => setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        ),
                        validator: (value) => value != _passwordController.text
                            ? 'Mật khẩu xác nhận không khớp.'
                            : null,
                        onSubmitted: (_) => isLoading ? null : _submit(),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: isLoading
                            ? null
                            : (value) => setState(
                                () => _acceptedTerms = value ?? false,
                              ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: const Text(
                          'Tôi đồng ý Điều khoản sử dụng và Chính sách bảo mật.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: isLoading || !isConfigured ? null : _submit,
                        icon: isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Đăng ký'),
                      ),
                      const _OrDivider(),
                      OutlinedButton.icon(
                        onPressed: isLoading || !isConfigured
                            ? null
                            : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Tiếp tục với Google'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go(
                                authEntryLocation(
                                  '/login',
                                  widget.redirectPath,
                                ),
                              ),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !ref.read(authControllerProvider).isLoading,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !ref.read(authControllerProvider).isLoading,
      obscureText: obscureText,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _LocalDataNotice extends StatelessWidget {
  const _LocalDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_sync_outlined, color: AppTheme.primarySlate),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'CV đang lưu trên máy vẫn được giữ nguyên và có thể đồng bộ sau khi đăng ký.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('HOẶC', style: TextStyle(fontSize: 11)),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}
