import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../cv_editor/data/datasources/cv_remote_data_source.dart';
import '../../../cv_editor/domain/models/cv_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CvModel> _cvs = const [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isSignedIn => SupabaseService.client?.auth.currentSession != null;

  CvRemoteDataSource get _remoteDataSource => CvRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _loadCvs();
  }

  Future<void> _loadCvs() async {
    if (!_isSignedIn) {
      if (!mounted) return;
      setState(() {
        _cvs = const [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cvs = await _remoteDataSource.fetchUserCvs();
      if (!mounted) return;
      setState(() {
        _cvs = cvs;
        _isLoading = false;
      });
    } on CvRemoteDataSourceException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách CV. Hãy thử lại.';
      });
    }
  }

  Future<void> _openEditor([CvModel? cv]) async {
    await context.push('/editor', extra: cv);
    if (mounted) await _loadCvs();
  }

  Future<void> _deleteCv(CvModel cv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá CV?'),
        content: Text(
          'Bạn có chắc muốn xoá "${cv.title}" khỏi Supabase không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _remoteDataSource.deleteRemoteCv(cv.id);
      if (!mounted) return;
      _showMessage('Đã xoá CV khỏi Supabase.');
      await _loadCvs();
    } on CvRemoteDataSourceException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.client?.auth.signOut();
    } finally {
      if (mounted) context.go('/login');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          if (_isSignedIn)
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _isLoading ? null : _loadCvs,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: _isSignedIn ? 'Đăng xuất' : 'Đăng nhập',
            icon: Icon(
              _isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
            ),
            onPressed: _isSignedIn ? _signOut : () => context.go('/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCvs,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCvsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo CV mới'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primarySlate, Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.accentCyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý CV Chuẩn ATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSignedIn
                      ? 'CV của bạn đang được đồng bộ trên Supabase Singapore.'
                      : 'Đăng nhập để lưu và đồng bộ CV trên cloud.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách hồ sơ của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${_cvs.length} hồ sơ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          _buildErrorState()
        else if (!_isSignedIn)
          _buildSignedOutState()
        else if (_cvs.isEmpty)
          _buildEmptyState()
        else
          ..._cvs.map(_buildCvCard),
      ],
    );
  }

  Widget _buildCvCard(CvModel cv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(cv),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primarySlate.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: AppTheme.primarySlate,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cập nhật: ${_formatDate(cv.updatedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Xoá CV',
                onPressed: () => _deleteCv(cv),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _messageCard(
      icon: Icons.description_outlined,
      title: 'Chưa có CV trên cloud',
      message:
          'Tạo CV đầu tiên. Khi bấm Lưu, dữ liệu sẽ được ghi vào Supabase.',
      action: 'Tạo CV mới',
      onPressed: () => _openEditor(),
    );
  }

  Widget _buildSignedOutState() {
    return _messageCard(
      icon: Icons.cloud_off_outlined,
      title: 'Bạn chưa đăng nhập',
      message: 'Đăng nhập Supabase để tải và lưu CV của riêng bạn.',
      action: 'Đăng nhập',
      onPressed: () => context.go('/login'),
    );
  }

  Widget _buildErrorState() {
    return _messageCard(
      icon: Icons.cloud_sync_outlined,
      title: 'Không tải được dữ liệu',
      message: _errorMessage!,
      action: 'Thử lại',
      onPressed: _loadCvs,
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 44, color: AppTheme.primarySlate),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'chưa đồng bộ';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
