import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

class CvEditorScreen extends StatefulWidget {
  const CvEditorScreen({super.key});

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Personal Info Controllers
  final _fullNameController = TextEditingController(text: 'Nguyễn Tuấn Anh');
  final _roleController = TextEditingController(
    text: 'Flutter Software Engineer',
  );
  final _emailController = TextEditingController(text: 'tuananh@example.com');
  final _phoneController = TextEditingController(text: '0901 234 567');
  final _locationController = TextEditingController(text: 'Hà Nội, Việt Nam');
  final _summaryController = TextEditingController(
    text:
        'Kỹ sư phần mềm mobile chuyên sâu về Flutter, kiến trúc Clean Architecture, '
        'Riverpod và Supabase. Có kinh nghiệm tối ưu hóa hiệu năng ứng dụng di động.',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _handleAiOptimizeSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.accentCyan, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Gemini: Đang phân tích từ khóa tuyển dụng và tối ưu câu chữ...',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primarySlate,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trình chỉnh sửa CV'),
        actions: [
          IconButton(
            tooltip: 'Xem trước PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => context.push('/preview'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.accentTeal,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.accentTeal,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Cá nhân'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Học vấn'),
            Tab(icon: Icon(Icons.work_outline), text: 'Kinh nghiệm'),
            Tab(icon: Icon(Icons.psychology_outlined), text: 'Kỹ năng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Personal Info
          _buildPersonalInfoTab(),

          // Tab 2: Education
          _buildPlaceholderTab(
            icon: Icons.school_rounded,
            title: 'Học vấn & Bằng cấp',
            subtitle: 'Thêm thông tin trường đại học, niên khóa, GPA của bạn.',
          ),

          // Tab 3: Experience
          _buildPlaceholderTab(
            icon: Icons.work_rounded,
            title: 'Kinh nghiệm làm việc',
            subtitle: 'Mô tả dự án, vị trí công tác và kết quả đo lường được.',
          ),

          // Tab 4: Skills
          _buildPlaceholderTab(
            icon: Icons.psychology_rounded,
            title: 'Kỹ năng chuyên môn',
            subtitle:
                'Phân loại kỹ năng kỹ thuật, ngôn ngữ lập trình, ngoại ngữ.',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/preview'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Xem trước CV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thông tin cơ bản',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Vị trí ứng tuyển mục tiêu *',
              prefixIcon: Icon(Icons.work_history_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ / Thành phố',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Professional Summary Section with AI Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tóm tắt bản thân (Summary)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: _handleAiOptimizeSummary,
                icon: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.accentTeal,
                  size: 16,
                ),
                label: const Text(
                  'Tối ưu AI',
                  style: TextStyle(
                    color: AppTheme.accentTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _summaryController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Viết ngắn gọn từ 3-5 câu giới thiệu năng lực cốt lõi...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primarySlate.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primarySlate),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm mục mới'),
            ),
          ],
        ),
      ),
    );
  }
}
