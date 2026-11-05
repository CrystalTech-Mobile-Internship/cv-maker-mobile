import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/skill_model.dart';
import 'skill_bank_sheet.dart';

/// Tab for displaying and managing Technical & Professional Skills.
class SkillsTab extends StatelessWidget {
  const SkillsTab({
    super.key,
    required this.skills,
    required this.onAddSkill,
    this.onAddSkillModel,
    this.onEditSkill,
    this.onDeleteSkill,
    this.onUseStarterSkills,
    this.language = 'vi',
  });

  final List<SkillModel> skills;
  final VoidCallback onAddSkill;
  final ValueChanged<SkillModel>? onAddSkillModel;
  final ValueChanged<SkillModel>? onEditSkill;
  final ValueChanged<String>? onDeleteSkill;
  final VoidCallback? onUseStarterSkills;
  final String language;

  bool get _isEn => language == 'en';

  void _openSkillBank(BuildContext context) {
    SkillBankSheet.show(
      context: context,
      existingSkills: skills,
      language: language,
      onAddSkill: (newSkill) {
        onAddSkillModel?.call(newSkill);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primarySlate.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 38,
                  color: AppTheme.primarySlate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEn ? 'Professional Skills' : 'Kỹ năng chuyên môn',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isEn
                    ? 'Categorize technical skills, frameworks, tools, and languages.'
                    : 'Phân loại kỹ năng kỹ thuật, ngôn ngữ lập trình, ngoại ngữ.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onAddSkill,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_isEn ? 'Add Custom' : 'Tự thêm'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    key: const Key('open-skill-bank-empty-btn'),
                    onPressed: () => _openSkillBank(context),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isEn ? 'Skill Bank' : 'Kho kỹ năng'),
                  ),
                ],
              ),
              if (onUseStarterSkills != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('use-starter-skills-btn'),
                  onPressed: onUseStarterSkills,
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: Text(_isEn ? 'Use Starter Skills ("Fill-in")' : 'Dùng bộ kỹ năng mẫu ("Điền mẫu nhanh")'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final hardSkills = skills
        .where((s) => s.category == SkillCategory.hard)
        .toList();
    final softSkills = skills
        .where((s) => s.category == SkillCategory.soft)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Skill bank banner & quick discovery action
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.brandIndigo.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brandIndigo.withAlpha(35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 20, color: AppTheme.brandIndigo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isEn
                      ? '${skills.length} skills added. Need more ideas?'
                      : 'Đã thêm ${skills.length} kỹ năng. Muốn thêm gợi ý?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('open-skill-bank-header-btn'),
                onPressed: () => _openSkillBank(context),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(_isEn ? 'Skill Bank' : 'Kho kỹ năng'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.brandIndigo,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        if (hardSkills.isNotEmpty) ...[
          _buildCategoryHeader(
            context,
            icon: Icons.code_rounded,
            title: _isEn
                ? 'Technical & Hard Skills'
                : 'Kỹ năng chuyên môn (Hard Skills)',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hardSkills.map(_buildSkillChip).toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (softSkills.isNotEmpty) ...[
          _buildCategoryHeader(
            context,
            icon: Icons.groups_rounded,
            title: _isEn
                ? 'Soft Skills & Methods'
                : 'Kỹ năng mềm & Phương pháp',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: softSkills.map(_buildSkillChip).toList(),
          ),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddSkill,
          icon: const Icon(Icons.add_rounded),
          label: Text(_isEn ? 'Add Another Skill' : 'Thêm kỹ năng mới'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primarySlate),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.primarySlate,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(SkillModel skill) {
    return InputChip(
      elevation: 0,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      avatar: const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: AppTheme.primarySlate,
      ),
      label: Text(
        skill.proficiency > 0
            ? '${skill.name} (${skill.proficiency}%)'
            : skill.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      tooltip: _isEn ? 'Tap to edit' : 'Chạm để chỉnh sửa',
      onPressed: onEditSkill == null ? null : () => onEditSkill!(skill),
      onDeleted: onDeleteSkill != null ? () => onDeleteSkill!(skill.id) : null,
    );
  }
}
