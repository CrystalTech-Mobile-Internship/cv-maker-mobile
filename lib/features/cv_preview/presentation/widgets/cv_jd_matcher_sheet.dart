import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../domain/services/cv_jd_matcher_service.dart';

/// Modal bottom sheet that compares candidate's CV against Job Description (JD)
/// keywords and provides instant gap-analysis with 1-tap skill addition.
class CvJdMatcherSheet extends StatefulWidget {
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => CvJdMatcherSheet(
        cv: cv,
        onAddMissingSkill: onAddMissingSkill,
        isEnglish: isEnglish,
      ),
    );
  }

  @override
  State<CvJdMatcherSheet> createState() => _CvJdMatcherSheetState();
}

class _CvJdMatcherSheetState extends State<CvJdMatcherSheet> {
  late String _selectedPresetId;
  late CvModel _currentCv;

  @override
  void initState() {
    super.initState();
    _currentCv = widget.cv;
    _selectedPresetId = CvJdMatcherService.presets.first.id;
  }

  void _handleAddMissingKeyword(String keyword) {
    final newSkill = SkillModel(
      id: 'skill-${DateTime.now().microsecondsSinceEpoch}',
      name: keyword,
      category: SkillCategory.hard,
      proficiency: 80,
    );

    final updatedSkills = List<SkillModel>.from(_currentCv.skills)
      ..add(newSkill);
    setState(() {
      _currentCv = _currentCv.copyWith(skills: updatedSkills);
    });

    widget.onAddMissingSkill(newSkill);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEnglish
              ? 'Added "$keyword" to your CV skills.'
              : 'Đã thêm "$keyword" vào kỹ năng trong CV.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPreset = CvJdMatcherService.presets.firstWhere(
      (p) => p.id == _selectedPresetId,
      orElse: () => CvJdMatcherService.presets.first,
    );

    final report = CvJdMatcherService.evaluate(
      cv: _currentCv,
      targetKeywords: currentPreset.keywords,
    );

    final score = report.score;
    final scoreColor = score >= 80
        ? const Color(0xFF15803D)
        : (score >= 50 ? Colors.amber.shade800 : AppTheme.dangerRose);
    final scoreBg = score >= 80
        ? const Color(0xFFF0FDF4)
        : (score >= 50 ? Colors.amber.shade50 : const Color(0xFFFFF1F2));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppTheme.brandIndigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnglish
                            ? 'Match with a job posting'
                            : 'So khớp với tin tuyển dụng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isEnglish
                            ? 'Compare your CV with job requirements to improve your chances'
                            : 'Xem CV đã có đủ kỹ năng nhà tuyển dụng cần chưa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Preset Job Roles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: CvJdMatcherService.presets.map((preset) {
                final isSelected = preset.id == _selectedPresetId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('jd-preset-${preset.id}'),
                    label: Text(
                      preset.title(widget.isEnglish ? 'en' : 'vi'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.brandIndigo,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                    onSelected: (_) =>
                        setState(() => _selectedPresetId = preset.id),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 12),

          // Match Score Card & Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scoreBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scoreColor.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: scoreColor, width: 3),
                          ),
                          child: Text(
                            '$score%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                score >= 80
                                    ? (widget.isEnglish
                                          ? 'Excellent Match!'
                                          : 'Rất phù hợp')
                                    : (score >= 50
                                          ? (widget.isEnglish
                                                ? 'Good Match'
                                                : 'Khá phù hợp')
                                          : (widget.isEnglish
                                                ? 'Needs Keywords'
                                                : 'Cần bổ sung kỹ năng')),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.isEnglish
                                    ? '${report.matchedKeywords.length}/${report.totalKeywords} core keywords found in your CV'
                                    : 'CV có ${report.matchedKeywords.length}/${report.totalKeywords} kỹ năng được yêu cầu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Missing Keywords Section (Actionable)
                  if (report.missingKeywords.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isEnglish
                              ? 'Missing Keywords (${report.missingKeywords.length})'
                              : 'Kỹ năng còn thiếu (${report.missingKeywords.length})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isEnglish
                          ? 'Tap "+ Add" to include a missing keyword into your skills:'
                          : 'Chạm "+ Thêm" nếu bạn có kỹ năng đó:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: report.missingKeywords.map((kw) {
                        return ActionChip(
                          key: Key('add-missing-$kw'),
                          avatar: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.deepOrange,
                          ),
                          label: Text(
                            kw,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                          backgroundColor: Colors.deepOrange.withAlpha(12),
                          side: BorderSide(
                            color: Colors.deepOrange.withAlpha(40),
                          ),
                          onPressed: () => _handleAddMissingKeyword(kw),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Matched Keywords Section
                  if (report.matchedKeywords.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isEnglish
                              ? 'Matched Keywords (${report.matchedKeywords.length})'
                              : 'Kỹ năng đã có (${report.matchedKeywords.length})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: report.matchedKeywords.map((kw) {
                        return Chip(
                          avatar: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF15803D),
                          ),
                          label: Text(
                            kw,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF166534),
                            ),
                          ),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
