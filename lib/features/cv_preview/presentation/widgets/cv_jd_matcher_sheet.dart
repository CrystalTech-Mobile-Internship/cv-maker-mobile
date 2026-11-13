import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../ai_tools/presentation/widgets/job_posting_input.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../domain/services/cv_jd_matcher_service.dart';

/// Compares the CV with a job posting pasted as a link or as text.
class CvJdMatcherSheet extends ConsumerStatefulWidget {
  const CvJdMatcherSheet({
    super.key,
    required this.cv,
    required this.onAddMissingSkill,
    this.isEnglish = false,
  });

  final CvModel cv;
  final ValueChanged<SkillModel> onAddMissingSkill;
  final bool isEnglish;

  static Future<void> show({
    required BuildContext context,
    required CvModel cv,
    required ValueChanged<SkillModel> onAddMissingSkill,
    bool isEnglish = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CvJdMatcherSheet(
        cv: cv,
        onAddMissingSkill: onAddMissingSkill,
        isEnglish: isEnglish,
      ),
    );
  }

  @override
  ConsumerState<CvJdMatcherSheet> createState() => _CvJdMatcherSheetState();
}

class _CvJdMatcherSheetState extends ConsumerState<CvJdMatcherSheet> {
  final _input = TextEditingController();
  late CvModel _cv = widget.cv;
  String? _jobText;

  bool get _en => widget.isEnglish;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _match() async {
    FocusScope.of(context).unfocus();
    final text = await resolveJobPostingInput(
      context,
      ref,
      _input.text,
      redirectPath: '/home',
    );
    if (text == null || !mounted) return;
    setState(() => _jobText = text);
  }

  void _addSkill(String keyword) {
    final skill = SkillModel(
      id: 'skill-${DateTime.now().microsecondsSinceEpoch}',
      name: keyword,
      category: SkillCategory.hard,
      proficiency: 70,
    );
    setState(() => _cv = _cv.copyWith(skills: [..._cv.skills, skill]));
    widget.onAddMissingSkill(skill);
  }

  @override
  Widget build(BuildContext context) {
    final report = _jobText == null
        ? null
        : CvJdMatcherService.evaluateJobDescription(
            cv: _cv,
            jobDescription: _jobText!,
          );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _en ? 'Match a job posting' : 'So khớp tin tuyển dụng',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('jd-matcher-input'),
                controller: _input,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: _en
                      ? 'Paste a job link or the job description'
                      : 'Dán link hoặc nội dung tin tuyển dụng',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('jd-matcher-submit'),
                onPressed: _match,
                child: Text(_en ? 'Compare' : 'So khớp'),
              ),
              if (report != null) ...[
                const SizedBox(height: 16),
                _Result(report: report, isEnglish: _en, onAdd: _addSkill),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.report,
    required this.isEnglish,
    required this.onAdd,
  });

  final JdMatchReport report;
  final bool isEnglish;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    if (report.totalKeywords == 0) {
      return Text(
        isEnglish
            ? 'No skills found. Paste the requirements section.'
            : 'Chưa nhận ra kỹ năng nào. Hãy dán phần "Yêu cầu" của tin.',
        style: const TextStyle(color: AppTheme.mutedText),
      );
    }
    final score = report.score;
    final color = score >= 75
        ? AppTheme.successGreen
        : score >= 50
        ? AppTheme.warningAmber
        : AppTheme.dangerRose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$score%',
              key: const Key('jd-matcher-score'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEnglish
                    ? '${report.matchedKeywords.length}/${report.totalKeywords} required skills on your CV'
                    : 'CV có ${report.matchedKeywords.length}/${report.totalKeywords} kỹ năng được yêu cầu',
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ),
          ],
        ),
        if (report.missingKeywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            isEnglish ? 'Missing — tap to add' : 'Còn thiếu — chạm để thêm',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in report.missingKeywords)
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  label: Text(keyword),
                  onPressed: () => onAdd(keyword),
                ),
            ],
          ),
        ],
        if (report.matchedKeywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            isEnglish ? 'Already on your CV' : 'Đã có',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in report.matchedKeywords)
                Chip(
                  label: Text(keyword),
                  side: BorderSide.none,
                  backgroundColor: AppTheme.tealSurface,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
