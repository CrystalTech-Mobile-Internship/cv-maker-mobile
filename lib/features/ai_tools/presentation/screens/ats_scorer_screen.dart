import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../../cv_management/presentation/controllers/cv_list_provider.dart';
import '../../../cv_preview/domain/services/cv_jd_matcher_service.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/cv_plain_text.dart';
import '../../domain/services/jd_keyword_extractor.dart';
import '../controllers/ai_assistant_providers.dart';
import '../widgets/ai_access_guard.dart';
import '../widgets/ai_tailor_review_sheet.dart';
import '../widgets/cover_letter_sheet.dart';
import 'interview_practice_screen.dart';

/// Scores a saved CV against a pasted job description. Runs fully offline:
/// keywords are extracted from the JD with [JdKeywordExtractor] and matched
/// against the CV with [CvJdMatcherService].
class AtsScorerScreen extends ConsumerStatefulWidget {
  const AtsScorerScreen({super.key});

  @override
  ConsumerState<AtsScorerScreen> createState() => _AtsScorerScreenState();
}

class _AtsScorerScreenState extends ConsumerState<AtsScorerScreen> {
  final _jdController = TextEditingController();
  String? _selectedCvId;
  JdMatchReport? _report;
  String? _reportCvId;

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  CvModel? _selectedCv(List<CvModel> cvs) {
    if (cvs.isEmpty) return null;
    return cvs.firstWhere(
      (cv) => cv.id == _selectedCvId,
      orElse: () => cvs.first,
    );
  }

  void _analyze(CvModel? cv) {
    FocusScope.of(context).unfocus();
    if (cv == null) {
      _toast('Hãy tạo hoặc nhập một CV trước khi chấm điểm.');
      return;
    }
    final jd = _jdController.text.trim();
    if (jd.length < 20) {
      _toast('Hãy dán mô tả công việc (ít nhất 20 ký tự).');
      return;
    }
    final report = CvJdMatcherService.evaluateJobDescription(
      cv: cv,
      jobDescription: jd,
    );
    if (report.totalKeywords == 0) {
      _toast(
        'Chưa nhận diện được kỹ năng nào trong JD. Hãy dán phần "Yêu cầu".',
      );
    }
    setState(() {
      _report = report;
      _reportCvId = cv.id;
    });
  }

  Future<void> _addMissingSkills(CvModel cv, List<String> keywords) async {
    if (keywords.isEmpty) return;
    final existing = cv.skills.map((s) => s.name.toLowerCase()).toSet();
    final now = DateTime.now().toUtc();
    final additions = [
      for (var i = 0; i < keywords.length; i++)
        if (!existing.contains(keywords[i].toLowerCase()))
          SkillModel(
            id: 'skill-${now.microsecondsSinceEpoch}-$i',
            name: keywords[i],
            category: SkillCategory.hard,
            proficiency: 60,
          ),
    ];
    if (additions.isEmpty) return;
    final saved = await ref
        .read(cvRepositoryProvider)
        .save(cv.copyWith(skills: [...cv.skills, ...additions]), now: now);
    if (!mounted) return;
    _toast(
      'Đã thêm ${additions.length} kỹ năng. Chỉ giữ lại kỹ năng bạn thật sự có.',
    );
    _analyze(saved);
  }

  Future<void> _writeCoverLetter(CvModel cv) async {
    final jd = _jdController.text.trim();
    if (jd.length < 40) {
      _toast('Hãy dán JD đầy đủ hơn (ít nhất 40 ký tự) để AI viết thư.');
      return;
    }
    if (!await ensureAiAccess(context, ref, redirectPath: '/ats-scorer')) {
      return;
    }
    if (!mounted) return;
    try {
      final letter = await runWithAiProgress(
        context,
        'AI đang viết thư xin việc...',
        () => ref
            .read(aiAssistantRepositoryProvider)
            .coverLetter(
              cvText: cvPlainText(cv),
              jobDescription: jd,
              company: '',
              language: cv.language,
            ),
      );
      if (!mounted) return;
      await showCoverLetterSheet(context, letter);
    } on AiWritingFailure catch (failure) {
      if (mounted) _toast(describeAiFailure(failure));
    }
  }

  Future<void> _tailorWithAi(CvModel cv) async {
    final jd = _jdController.text.trim();
    if (jd.length < 40) {
      _toast('Hãy dán JD đầy đủ hơn (ít nhất 40 ký tự) để AI tối ưu CV.');
      return;
    }
    if (!await ensureAiAccess(context, ref, redirectPath: '/ats-scorer')) {
      return;
    }
    if (!mounted) return;
    try {
      final result = await runWithAiProgress(
        context,
        'AI đang tối ưu CV theo JD...',
        () => ref
            .read(aiAssistantRepositoryProvider)
            .tailorCv(cv: cv, jobDescription: jd),
      );
      if (!mounted) return;
      final confirmed = await showAiTailorReviewSheet(
        context,
        cv: cv,
        result: result,
      );
      if (confirmed == null || !mounted) return;
      final now = DateTime.now().toUtc();
      final copy = applyTailoring(
        cv,
        result,
        newId: 'tailored-${now.microsecondsSinceEpoch}',
        title: '${cv.title} (tối ưu theo JD)',
        confirmedSkills: confirmed,
        now: now,
      );
      final saved = await ref.read(cvRepositoryProvider).save(copy, now: now);
      if (!mounted) return;
      _toast('Đã tạo bản CV tối ưu. CV gốc được giữ nguyên.');
      context.push('/editor', extra: saved);
    } on AiWritingFailure catch (failure) {
      if (mounted) _toast(describeAiFailure(failure));
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cvsAsync = ref.watch(cvListStreamProvider);
    final cvs = cvsAsync.valueOrNull ?? const <CvModel>[];
    final cv = _selectedCv(cvs);
    final report = _reportCvId == cv?.id ? _report : null;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Chấm điểm ATS'),
        actions: const [AiQuotaChip(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            if (cvsAsync.isLoading && cvs.isEmpty)
              const LinearProgressIndicator()
            else if (cvs.isEmpty)
              const _EmptyCvNotice()
            else
              DropdownButtonFormField<String>(
                key: const ValueKey('ats-cv-picker'),
                initialValue: cv?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'CV cần chấm'),
                items: [
                  for (final item in cvs)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedCvId = value),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('ats-jd-input'),
              controller: _jdController,
              minLines: 7,
              maxLines: 12,
              maxLength: 8000,
              decoration: const InputDecoration(
                labelText: 'Mô tả công việc (Job Description)',
                alignLabelWithHint: true,
                hintText:
                    'Dán JD từ nhà tuyển dụng: yêu cầu kỹ năng, kinh nghiệm, công cụ...',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _analyze(cv),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Chấm điểm CV theo JD'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phân tích chạy ngay trên máy, không gửi CV hay JD ra ngoài.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
            if (report != null && cv != null) ...[
              const SizedBox(height: 18),
              _ScoreCard(report: report),
              const SizedBox(height: 12),
              _KeywordCard(
                report: report,
                onAddMissing: () =>
                    _addMissingSkills(cv, report.missingKeywords),
                onOpenEditor: () => context.push('/editor', extra: cv),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('ats-tailor'),
                onPressed: () => _tailorWithAi(cv),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  'AI tối ưu CV theo JD (${AiCreditCost.tailorCv} lượt)',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('ats-interview'),
                onPressed: () => context.push(
                  '/interview-practice',
                  extra: InterviewPracticeArgs(
                    cvId: cv.id,
                    jobDescription: _jdController.text.trim(),
                  ),
                ),
                icon: const Icon(Icons.record_voice_over_outlined),
                label: const Text('Luyện phỏng vấn cho vị trí này'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('ats-cover-letter'),
                onPressed: () => _writeCoverLetter(cv),
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(
                  'AI viết thư xin việc theo JD (${AiCreditCost.coverLetter} lượt)',
                ),
              ),
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

class _EmptyCvNotice extends StatelessWidget {
  const _EmptyCvNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.amberSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Bạn chưa có CV nào trên máy. Hãy tạo CV mới hoặc nhập từ PDF/Word ở màn hình chính.',
        style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final JdMatchReport report;

  @override
  Widget build(BuildContext context) {
    final score = report.score;
    final color = score >= 75
        ? AppTheme.createAction
        : score >= 50
        ? AppTheme.warningAmber
        : AppTheme.dangerRose;
    final verdict = report.totalKeywords == 0
        ? 'Không đủ dữ liệu để chấm.'
        : score >= 75
        ? 'CV khớp tốt với JD. Hãy đảm bảo từ khóa xuất hiện trong mô tả kinh nghiệm.'
        : score >= 50
        ? 'Khá phù hợp. Bổ sung kỹ năng còn thiếu (nếu bạn thật sự có) để tăng điểm.'
        : 'Độ khớp thấp. Cân nhắc điều chỉnh tóm tắt, kỹ năng và dự án theo JD.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                Text(
                  '$score%',
                  key: const ValueKey('ats-score-text'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khớp ${report.matchedKeywords.length}/${report.totalKeywords} từ khóa',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verdict,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordCard extends StatelessWidget {
  const _KeywordCard({
    required this.report,
    required this.onAddMissing,
    required this.onOpenEditor,
  });

  final JdMatchReport report;
  final VoidCallback onAddMissing;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Từ khóa đã khớp',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _chips(report.matchedKeywords, const Color(0xFFD1FAE5), 'Chưa có'),
          const SizedBox(height: 14),
          const Text(
            'Nên bổ sung',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _chips(
            report.missingKeywords,
            const Color(0xFFFFEDD5),
            'Không thiếu từ khóa nào',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (report.missingKeywords.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: onAddMissing,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Thêm kỹ năng còn thiếu'),
                ),
              TextButton.icon(
                onPressed: onOpenEditor,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Mở trình chỉnh sửa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips(List<String> items, Color background, String emptyText) {
    if (items.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: AppTheme.mutedText));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Chip(
            label: Text(item),
            backgroundColor: background,
            side: BorderSide.none,
          ),
      ],
    );
  }
}
