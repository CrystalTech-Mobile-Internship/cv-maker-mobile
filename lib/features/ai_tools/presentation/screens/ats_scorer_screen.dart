import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AtsScorerScreen extends StatefulWidget {
  const AtsScorerScreen({super.key});

  @override
  State<AtsScorerScreen> createState() => _AtsScorerScreenState();
}

class _AtsScorerScreenState extends State<AtsScorerScreen> {
  final _jdController = TextEditingController();
  bool _showPreviewResult = false;

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  void _analyze() {
    final hasJd = _jdController.text.trim().length >= 20;
    if (!hasJd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy dán mô tả công việc (ít nhất 20 ký tự).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _showPreviewResult = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Giao diện chấm điểm đã sẵn sàng. Kết nối Gemini/Groq sẽ làm sau.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(title: const Text('Chấm điểm ATS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            TextField(
              controller: _jdController,
              minLines: 7,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Mô tả công việc (Job Description)',
                alignLabelWithHint: true,
                hintText:
                    'Dán JD từ nhà tuyển dụng: yêu cầu kỹ năng, kinh nghiệm, công cụ...',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Chấm điểm CV theo JD'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phần xử lý AI chưa kết nối. Kết quả bên dưới là giao diện minh họa.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
            if (_showPreviewResult) ...[
              const SizedBox(height: 18),
              const _ScorePreview(),
              const SizedBox(height: 12),
              const _KeywordPreview(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF312E81),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ATS Scorer & JD Matcher',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'So khớp từ khóa giữa CV và tin tuyển dụng, gợi ý kỹ năng còn thiếu trước khi nộp hồ sơ.',
            style: TextStyle(color: Color(0xFFC7D2FE), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.72,
                  strokeWidth: 8,
                  color: AppTheme.createAction,
                  backgroundColor: const Color(0xFFCCFBF1),
                ),
                const Text(
                  '72%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Độ phù hợp minh họa',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'CV đang khớp khá tốt với JD. Bổ sung thêm từ khóa còn thiếu để tăng điểm.',
                  style: TextStyle(color: AppTheme.mutedText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordPreview extends StatelessWidget {
  const _KeywordPreview();

  @override
  Widget build(BuildContext context) {
    const missing = ['Riverpod', 'CI/CD', 'SQLite', 'Supabase RLS'];
    const matched = ['Flutter', 'Clean Architecture', 'PDF'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Từ khóa khớp',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in matched)
                Chip(
                  label: Text(item),
                  backgroundColor: const Color(0xFFD1FAE5),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Nên bổ sung',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in missing)
                Chip(
                  label: Text(item),
                  backgroundColor: const Color(0xFFFFEDD5),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
