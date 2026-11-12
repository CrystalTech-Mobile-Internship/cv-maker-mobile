import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../auth_redirect.dart';
import '../providers/auth_providers.dart';
import '../../../legal/presentation/legal_document_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectPath});

  final String? redirectPath;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    final result = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    _showMessage(result.message, isError: !result.isSuccess);
    if (result.isSuccess && !result.requiresEmailConfirmation) {
      context.go(safeAuthRedirect(widget.redirectPath) ?? '/home');
    }
  }

  Future<void> _signInWithGoogle() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted) return;
    if (!result.isSuccess) _showMessage(result.message, isError: true);
  }

  Future<void> _continueAsGuest() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .continueAsGuest();
    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/home');
    } else {
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
    final repository = ref.watch(authRepositoryProvider);
    final isConfigured = repository.isConfigured;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Đăng nhập tài khoản',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _emailController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              enabled: !isLoading,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => isLoading ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Hiện mật khẩu'
                                      : 'Ẩn mật khẩu',
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push('/forgot-password'),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            FilledButton(
                              onPressed: isLoading || !isConfigured
                                  ? null
                                  : _submit,
                              child: isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Đăng nhập'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: isLoading || !isConfigured
                                  ? null
                                  : _signInWithGoogle,
                              icon: const Icon(Icons.account_circle_outlined),
                              label: const Text('Tiếp tục với Google'),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(
                                      authEntryLocation(
                                        '/register',
                                        widget.redirectPath,
                                      ),
                                    ),
                              child: const Text(
                                'Chưa có tài khoản? Tạo tài khoản',
                              ),
                            ),
                            const _OrDivider(),
                            OutlinedButton.icon(
                              onPressed: isLoading ? null : _continueAsGuest,
                              icon: const Icon(Icons.offline_bolt_outlined),
                              label: const Text('Dùng thử không cần tài khoản'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isConfigured) ...[
                    Text(
                      'Hiện chưa đăng nhập được. Bạn vẫn có thể dùng thử không cần tài khoản.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const LegalLinksText(textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primarySlate,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.description_rounded,
            size: 40,
            color: AppTheme.primarySlate,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppConstants.appName,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('HOẶC'),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}
