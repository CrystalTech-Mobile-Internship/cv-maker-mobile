import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class CvPreviewScreen extends StatefulWidget {
  const CvPreviewScreen({super.key});

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  String _selectedTemplate = 'harvard_ats';
  bool _isExporting = false;

  void _handleExportPdf() {
    setState(() => _isExporting = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Đã kết xuất file PDF chuẩn vector A4 thành công!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem trước & Xuất PDF'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTemplate,
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primarySlate),
              items: const [
                DropdownMenuItem(
                  value: 'harvard_ats',
                  child: Text('Mẫu Harvard ATS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                DropdownMenuItem(
                  value: 'modern_minimalist',
                  child: Text('Mẫu Modern Minimalist', style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTemplate = val);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              // A4 Sheet Container Simulation
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Harvard ATS Header (Centered)
                    const Text(
                      'NGUYỄN TUẤN ANH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'FLUTTER SOFTWARE ENGINEER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hà Nội, Việt Nam • 0901 234 567 • tuananh@example.com • github.com/TuanAnh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.black, thickness: 1.2),
                    const SizedBox(height: 10),

                    // Section 1: Summary
                    _buildSectionHeader('TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP'),
                    const SizedBox(height: 6),
                    const Text(
                      'Kỹ sư phần mềm mobile chuyên sâu về Flutter, kiến trúc Clean Architecture, '
                      'State Management (Riverpod) và tích hợp Backend-as-a-Service (Supabase). '
                      'Đam mê tối ưu hóa trải nghiệm người dùng và xây dựng hệ thống bền vững.',
                      style: TextStyle(fontSize: 11.5, height: 1.45, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Education
                    _buildSectionHeader('HỌC VẤN'),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ĐẠI HỌC CÔNG NGHỆ',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '2022 - 2026',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const Text(
                      'Cử nhân Kỹ thuật Phần mềm (Software Engineering) - GPA: 3.6/4.0',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Experience
                    _buildSectionHeader('KINH NGHIỆM LÀM VIỆC & DỰ ÁN'),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DỰ ÁN SMART CV MAKER MOBILE',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '10/2026 - Hiện tại',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const Text(
                      'Fullstack Mobile Engineer',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    _buildBulletPoint('Thiết kế kiến trúc Clean Architecture nhiều tầng tách biệt presentation, domain và data.'),
                    _buildBulletPoint('Tối ưu hóa công cụ render PDF A4 vector độ nét cao, ngăn chặn tràn trang thông minh.'),
                    _buildBulletPoint('Tích hợp mô hình AI phân tích từ khóa và tính điểm tương thích hệ thống ATS.'),
                    const SizedBox(height: 16),

                    // Section 4: Skills
                    _buildSectionHeader('KỸ NĂNG CHUYÊN MÔN'),
                    const SizedBox(height: 6),
                    const Text(
                      '• Ngôn ngữ & Framework: Flutter, Dart, TypeScript, Kotlin\n'
                      '• Backend & Database: Supabase, PostgreSQL, Row-Level Security, REST API\n'
                      '• AI & Tools: Google Gemini AI, Git Flow, Figma, Vector PDF Engine',
                      style: TextStyle(fontSize: 11, height: 1.45, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _handleExportPdf,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(_isExporting ? 'Đang xuất PDF...' : 'Tải xuống File PDF (A4)'),
          ),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.black,
          ),
        ),
        const Divider(color: Colors.black54, thickness: 0.8, height: 6),
      ],
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, height: 1.35, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
