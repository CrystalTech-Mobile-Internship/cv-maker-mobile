import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_management/presentation/controllers/reusable_profile_provider.dart';
import '../providers/auth_providers.dart';

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
              const Text(
                'Đăng nhập để quản lý tài khoản và đồng bộ CV',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
      if (widget.embedded) return guestContent;
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
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
                    TextField(
                      controller: _displayNameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (reusableProfile != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.tealSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.accentTeal.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.contact_page_outlined,
                            color: AppTheme.accentTeal,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Hồ sơ dùng lại',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reusableProfile.personalInfo.fullName.isEmpty
                            ? reusableProfile.title
                            : reusableProfile.personalInfo.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (reusableProfile.personalInfo.targetRole.isNotEmpty)
                        Text(reusableProfile.personalInfo.targetRole),
                      const SizedBox(height: 5),
                      Text(
                        '${reusableProfile.personalInfo.email}'
                        '${reusableProfile.skills.isEmpty ? '' : ' • ${reusableProfile.skills.length} kỹ năng'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thông tin này có thể được chọn lại khi tạo CV mới.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _AccountInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _AccountInfoTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Xác nhận email',
                      value: user.isEmailConfirmed
                          ? 'Đã xác nhận'
                          : 'Chưa xác nhận',
                    ),
                    _AccountInfoTile(
                      icon: Icons.link_rounded,
                      label: 'Phương thức đăng nhập',
                      value: user.provider,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                tileColor: Colors.white,
                leading: const Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primarySlate,
                ),
                title: const Text('Chấm điểm CV'),
                subtitle: const Text('So sánh CV với tin tuyển dụng'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/ats-scorer'),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                tileColor: Colors.white,
                leading: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.primarySlate,
                ),
                title: const Text('Nâng cấp Pro'),
                subtitle: const Text('VietQR • Mẫu Premium'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/upgrade-pro'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu hồ sơ tài khoản'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => context.push('/reset-password'),
                icon: const Icon(Icons.password_rounded),
                label: const Text('Đổi mật khẩu'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _signOut,
                style: AppTheme.logoutButton,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
              const SizedBox(height: 12),
              Text(
                'CV trên thiết bị không bị xóa khi bạn cập nhật tài khoản hoặc đăng xuất.',
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
      appBar: AppBar(title: const Text('Tài khoản')),
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
      title: Text(label),
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
