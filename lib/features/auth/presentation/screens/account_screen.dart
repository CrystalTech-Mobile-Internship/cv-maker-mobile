import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/presentation/admin_providers.dart';
import '../../../../app/theme.dart';
import '../../../cv_management/presentation/controllers/reusable_profile_provider.dart';
import '../../../legal/presentation/legal_document_screen.dart';
import '../providers/auth_providers.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/i18n/language_menu_button.dart';
import '../../../../core/i18n/app_language.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.embedded = false});

  /// When embedded in Home, the parent owns the app bar and bottom navigation.
  final bool embedded;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _displayNameController = TextEditingController();
  String? _loadedUserId;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(_displayNameController.text);
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
  }

  Future<void> _signOut() async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    if (result.isSuccess) {
      context.go('/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final reusableProfile = ref.watch(reusableProfileProvider).asData?.value;
    if (user == null) {
      final guestContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 54,
                color: AppTheme.primarySlate,
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  'Đăng nhập để sao lưu CV và dùng trên nhiều thiết bị',
                  'Sign in to back up your CVs and use them on any device',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: Text(tr('Đăng nhập', 'Sign in')),
              ),
              const SizedBox(height: 20),
              const LegalLinksText(textAlign: TextAlign.center),
            ],
          ),
        ),
      );
      if (widget.embedded) return guestContent;
      return Scaffold(
        appBar: AppBar(
          leading: homeFallbackLeading(context),
          title: Text(tr('Tài khoản', 'Account')),
          actions: const [LanguageMenuButton(), SizedBox(width: 8)],
        ),
        body: guestContent,
      );
    }

    if (_loadedUserId != user.id) {
      _loadedUserId = user.id;
      _displayNameController.text = user.displayName;
    }

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _AccountCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFE0E7FF),
                      foregroundColor: AppTheme.brandIndigo,
                      child: Text(
                        (user.displayName.isNotEmpty
                                ? user.displayName
                                : user.email)
                            .characters
                            .first
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.brandIndigo),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.displayName.isEmpty ? user.email : user.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _displayNameController,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: tr('Tên hiển thị', 'Display name'),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: isLoading ? null : _saveProfile,
                            child: Text(tr('Lưu', 'Save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _AccountSectionTitle(tr('Thông tin', 'Details')),
              _AccountCard(
                child: Column(
                  children: [
                    _AccountInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountInfoTile(
                      icon: Icons.verified_user_outlined,
                      label: tr('Xác nhận email', 'Email confirmed'),
                      value: user.isEmailConfirmed
                          ? tr('Đã xác nhận', 'Confirmed')
                          : tr('Chưa xác nhận', 'Not confirmed'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountInfoTile(
                      icon: Icons.link_rounded,
                      label: tr('Đăng nhập bằng', 'Signed in with'),
                      value: user.provider == 'google'
                          ? 'Google'
                          : tr('Email và mật khẩu', 'Email and password'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountInfoTile(
                      icon: Icons.contact_page_outlined,
                      label: tr(
                        'Hồ sơ dùng lại khi tạo CV mới',
                        'Used to fill in new CVs',
                      ),
                      value: reusableProfile == null
                          ? tr('Chưa có', 'Missing')
                          : [
                              reusableProfile.personalInfo.fullName.isEmpty
                                  ? reusableProfile.title
                                  : reusableProfile.personalInfo.fullName,
                              if (reusableProfile
                                  .personalInfo
                                  .targetRole
                                  .isNotEmpty)
                                reusableProfile.personalInfo.targetRole,
                            ].join(' • '),
                    ),
                  ],
                ),
              ),
              _AccountSectionTitle(tr('Tiện ích', 'Tools')),
              _AccountCard(
                child: Column(
                  children: [
                    _AccountLinkTile(
                      icon: Icons.analytics_outlined,
                      title: tr('Chấm điểm CV', 'Score my CV'),
                      subtitle: tr(
                        'So sánh CV với tin tuyển dụng',
                        'Compare your CV with a job posting',
                      ),
                      onTap: () => context.push('/ats-scorer'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountLinkTile(
                      icon: Icons.workspace_premium_rounded,
                      title: tr('Nâng cấp Pro', 'Upgrade to Pro'),
                      subtitle: tr(
                        'Thêm lượt dùng, mẫu CV cao cấp',
                        'More uses and premium templates',
                      ),
                      onTap: () => context.push('/upgrade-pro'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountLinkTile(
                      icon: Icons.work_history_outlined,
                      title: tr('Theo dõi ứng tuyển', 'Job tracker'),
                      subtitle: tr(
                        'Việc đã nộp, lịch phỏng vấn',
                        'Applications and interviews',
                      ),
                      onTap: () => context.push('/job-tracker'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _AccountLinkTile(
                      key: const Key('account-support'),
                      icon: Icons.support_agent_rounded,
                      title: tr('Nhắn hỗ trợ', 'Contact support'),
                      subtitle: tr(
                        'Hỏi đáp, báo lỗi, thanh toán',
                        'Questions, bugs, payments',
                      ),
                      onTap: () => context.push('/support'),
                    ),
                    if (isAdmin) ...[
                      const Divider(height: 1, indent: 56),
                      _AccountLinkTile(
                        key: const Key('account-admin'),
                        icon: Icons.admin_panel_settings_outlined,
                        title: tr('Quản trị', 'Admin'),
                        subtitle: tr(
                          'Trả lời hỗ trợ, duyệt thanh toán',
                          'Reply to support, review payments',
                        ),
                        onTap: () => context.push('/admin'),
                      ),
                    ],
                    const Divider(height: 1, indent: 56),
                    _AccountLinkTile(
                      icon: Icons.password_rounded,
                      title: tr('Đổi mật khẩu', 'Change password'),
                      onTap: isLoading
                          ? null
                          : () => context.push('/reset-password'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _signOut,
                style: AppTheme.logoutButton,
                icon: const Icon(Icons.logout_rounded),
                label: Text(tr('Đăng xuất', 'Sign out')),
              ),
              const SizedBox(height: 12),
              const LegalLinksText(textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                tr(
                  'Đăng xuất không xóa CV trên máy.',
                  'Signing out does not delete CVs on this device.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return ColoredBox(color: AppTheme.surfaceLight, child: content);
    }
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Tài khoản', 'Account')),
        actions: const [LanguageMenuButton(), SizedBox(width: 8)],
      ),
      body: content,
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primarySlate),
      title: Text(label, style: const TextStyle(color: AppTheme.mutedText)),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryNavy,
        ),
      ),
    );
  }
}

class _AccountLinkTile extends StatelessWidget {
  const _AccountLinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primarySlate),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryNavy,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// Every block on the account page uses this one card style.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _AccountSectionTitle extends StatelessWidget {
  const _AccountSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppTheme.mutedText,
        ),
      ),
    );
  }
}
