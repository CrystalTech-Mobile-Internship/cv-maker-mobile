import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/project_model.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({
    super.key,
    required this.projects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onUseStarterProjects,
    this.language = 'vi',
  });

  final List<ProjectModel> projects;
  final VoidCallback onAdd;
  final ValueChanged<ProjectModel> onEdit;
  final ValueChanged<String> onDelete;
  final VoidCallback? onUseStarterProjects;
  final String language;

  @override
  Widget build(BuildContext context) {
    final isEn = language == 'en';
    if (projects.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            key: const Key('projects-empty-state'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primarySlate.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.folder_copy_outlined,
                  size: 38,
                  color: AppTheme.primarySlate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEn ? 'Projects' : 'Dự án nổi bật',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'Add personal, academic, or team projects.'
                    : 'Thêm dự án cá nhân, học tập hoặc làm theo nhóm.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(isEn ? 'Add Project' : 'Thêm dự án'),
              ),
              if (onUseStarterProjects != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('use-starter-projects-btn'),
                  onPressed: onUseStarterProjects,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(isEn ? 'Use Starter Project ("Fill-in")' : 'Dùng mẫu dự án ("Điền mẫu nhanh")'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...projects.map(
          (project) => Card(
            child: ListTile(
              title: Text(
                project.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  project.role,
                  if (project.teamSize != null)
                    isEn
                        ? 'Team ${project.teamSize}'
                        : 'Nhóm ${project.teamSize} người',
                  if (project.technologies.isNotEmpty)
                    project.technologies.join(', '),
                ].where((value) => value.isNotEmpty).join(' • '),
              ),
              onTap: () => onEdit(project),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(project.id),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(isEn ? 'Add Another Project' : 'Thêm dự án'),
        ),
      ],
    );
  }
}
