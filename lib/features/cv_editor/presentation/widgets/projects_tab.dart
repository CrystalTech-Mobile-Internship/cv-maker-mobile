import 'package:flutter/material.dart';

import '../../domain/models/project_model.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({
    super.key,
    required this.projects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.language = 'vi',
  });

  final List<ProjectModel> projects;
  final VoidCallback onAdd;
  final ValueChanged<ProjectModel> onEdit;
  final ValueChanged<String> onDelete;
  final String language;

  @override
  Widget build(BuildContext context) {
    final isEn = language == 'en';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Column(
              children: [
                const Icon(Icons.folder_copy_outlined, size: 52),
                const SizedBox(height: 12),
                Text(
                  isEn ? 'No projects yet' : 'Chưa có dự án',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isEn
                      ? 'Add personal, academic, or team projects.'
                      : 'Thêm dự án cá nhân, học tập hoặc làm theo nhóm.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isEn ? 'Add Project' : 'Thêm dự án'),
                ),
              ],
            ),
          )
        else ...[
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
      ],
    );
  }
}
