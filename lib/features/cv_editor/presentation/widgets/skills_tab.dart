import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/skill_model.dart';

/// Tab for displaying and managing Technical & Professional Skills.
class SkillsTab extends StatelessWidget {
  const SkillsTab({
    super.key,
    required this.skills,
    required this.onAddSkill,
    this.onDeleteSkill,
    this.language = 'vi',
  });

  final List<SkillModel> skills;
  final VoidCallback onAddSkill;
  final ValueChanged<String>? onDeleteSkill;
  final String language;

  bool get _isEn => language == 'en';

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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isEn
                    ? 'Categorize technical skills, frameworks, tools, and languages.'
                    : 'Phân loại kỹ năng kỹ thuật, ngôn ngữ lập trình, ngoại ngữ.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddSkill,
                icon: const Icon(Icons.add_rounded),
                label: Text(_isEn ? 'Add Skill' : 'Thêm mục mới'),
              ),
            ],
          ),
        ),
      );
    }

    final hardSkills =
        skills.where((s) => s.category == SkillCategory.hard).toList();
    final softSkills =
        skills.where((s) => s.category == SkillCategory.soft).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (hardSkills.isNotEmpty) ...[
          _buildCategoryHeader(
            context,
            icon: Icons.code_rounded,
            title: _isEn ? 'Technical & Hard Skills' : 'Kỹ năng chuyên môn (Hard Skills)',
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
            title: _isEn ? 'Soft Skills & Methods' : 'Kỹ năng mềm & Phương pháp',
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
          label: Text(_isEn ? '+ Add Another Skill' : '+ Thêm kỹ năng mới'),
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
        Icon(icon, size: 18, color: AppTheme.accentTeal),
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
    return Chip(
      elevation: 0,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.accentTeal),
      label: Text(
        skill.proficiency > 0
            ? '${skill.name} (${skill.proficiency}%)'
            : skill.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      onDeleted: onDeleteSkill != null ? () => onDeleteSkill!(skill.id) : null,
    );
  }
}
