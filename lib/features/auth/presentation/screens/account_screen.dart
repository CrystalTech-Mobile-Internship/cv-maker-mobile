import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

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
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Đăng nhập để quản lý tài khoản'),
          ),
        ),
      );
    }

    if (_loadedUserId != user.id) {
      _loadedUserId = user.id;
      _displayNameController.text = user.displayName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản Cloud')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    (user.displayName.isNotEmpty
                            ? user.displayName
                            : user.email)
                        .characters
                        .first
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _displayNameController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu hồ sơ tài khoản'),
                ),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => context.push('/reset-password'),
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('Đổi mật khẩu'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isLoading ? null : _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
                const SizedBox(height: 12),
                Text(
                  'CV trên thiết bị không bị xóa khi bạn cập nhật tài khoản hoặc đăng xuất.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
