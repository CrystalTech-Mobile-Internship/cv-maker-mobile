import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../../core/i18n/language_menu_button.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../../legal/presentation/legal_document_screen.dart';
import '../auth_redirect.dart';
import '../providers/auth_providers.dart';
import '../widgets/google_logo.dart';

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
    final onTryFree = isLoading ? null : _continueAsGuest;

    final form = _SignInCard(
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      isLoading: isLoading,
      isConfigured: isConfigured,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmit: _submit,
      onGoogle: _signInWithGoogle,
      onForgot: () => context.push('/forgot-password'),
      onRegister: () =>
          context.push(authEntryLocation('/register', widget.redirectPath)),
    );
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isConfigured) ...[
          Text(
            tr(
              'Hiện chưa đăng nhập được. Bạn vẫn có thể dùng thử không cần tài khoản.',
              'Sign-in is not available right now. You can still try it without an account.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        const LegalLinksText(textAlign: TextAlign.center),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  Expanded(child: _FreeIntro(wide: true, onTryFree: onTryFree)),
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  form,
                                  const SizedBox(height: 20),
                                  footer,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: LanguageMenuButton(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FreeIntro(wide: false, onTryFree: onTryFree),
                          const SizedBox(height: 24),
                          form,
                          const SizedBox(height: 20),
                          footer,
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 4, right: 4, child: LanguageMenuButton()),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tells first-time visitors the essentials: making a CV is free and needs
/// no account.
class _FreeIntro extends StatelessWidget {
  const _FreeIntro({required this.wide, required this.onTryFree});

  final bool wide;
  final VoidCallback? onTryFree;

  @override
  Widget build(BuildContext context) {
    final templateCount = CvTemplateCatalog.freeTemplates.length;
    final points = <(IconData, String)>[
      (
        Icons.description_outlined,
        tr(
          '$templateCount mẫu CV miễn phí, có cả mẫu có ảnh',
          '$templateCount free CV templates, some with a photo',
        ),
      ),
      (
        Icons.download_outlined,
        tr('Tải PDF và Word miễn phí', 'Free PDF and Word download'),
      ),
      (
        Icons.edit_note_rounded,
        tr(
          'Gợi ý viết lại nội dung, 15 lượt mỗi ngày',
          'Writing suggestions, 15 a day',
        ),
      ),
      (
        Icons.devices_outlined,
        tr('Dùng trên web và điện thoại', 'Works on the web and on your phone'),
      ),
    ];
    final titleColor = wide ? Colors.white : AppTheme.primaryNavy;
    final textColor = wide ? const Color(0xFFE0E7FF) : AppTheme.mutedText;
    final align = wide ? TextAlign.start : TextAlign.center;

    final content = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/brand/logo.png',
                width: 40,
                height: 40,
                filterQuality: FilterQuality.medium,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? 40 : 20),
        Text(
          tr('Tạo và sửa CV miễn phí', 'Build and edit your CV for free'),
          textAlign: align,
          style: TextStyle(
            fontSize: wide ? 40 : 26,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tr(
            'Không cần tài khoản để bắt đầu. Đăng nhập khi muốn lưu CV vào tài khoản.',
            'No account needed to start. Sign in when you want to keep CVs in your account.',
          ),
          textAlign: align,
          style: TextStyle(
            fontSize: wide ? 17 : 14.5,
            height: 1.45,
            color: textColor,
          ),
        ),
        SizedBox(height: wide ? 28 : 16),
        if (wide)
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(point.$1, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final point in points.take(3))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.softBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(point.$1, size: 15, color: AppTheme.brandIndigo),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          point.$2,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        SizedBox(height: wide ? 20 : 18),
        SizedBox(
          width: wide ? 340 : double.infinity,
          child: FilledButton.icon(
            key: const Key('login-try-free'),
            onPressed: onTryFree,
            style: FilledButton.styleFrom(
              backgroundColor: wide ? Colors.white : AppTheme.brandIndigo,
              foregroundColor: wide ? AppTheme.brandIndigo : Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              tr('Dùng thử không cần tài khoản', 'Try it without an account'),
            ),
          ),
        ),
      ],
    );

    if (!wide) return content;
    return Container(
      color: AppTheme.brandIndigo,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: content,
        ),
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.isConfigured,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onGoogle,
    required this.onForgot,
    required this.onRegister,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool isConfigured;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onForgot;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('Đăng nhập tài khoản', 'Sign in'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Để lưu CV và dùng trên mọi thiết bị.',
                'To keep your CVs on every device.',
              ),
              style: const TextStyle(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: isLoading || !isConfigured ? null : onGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const GoogleLogo(),
              label: Text(tr('Tiếp tục với Google', 'Continue with Google')),
            ),
            _OrDivider(label: tr('HOẶC DÙNG EMAIL', 'OR USE EMAIL')),
            TextField(
              controller: emailController,
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
              controller: passwordController,
              enabled: !isLoading,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => isLoading ? null : onSubmit(),
              decoration: InputDecoration(
                labelText: tr('Mật khẩu', 'Password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: obscurePassword
                      ? tr('Hiện mật khẩu', 'Show password')
                      : tr('Ẩn mật khẩu', 'Hide password'),
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgot,
                child: Text(tr('Quên mật khẩu?', 'Forgot password?')),
              ),
            ),
            FilledButton(
              onPressed: isLoading || !isConfigured ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(tr('Đăng nhập', 'Sign in')),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: isLoading ? null : onRegister,
              child: Text(
                tr(
                  'Chưa có tài khoản? Tạo tài khoản',
                  'New here? Create an account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
