import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/certification_model.dart';

class CertificationsTab extends StatelessWidget {
  const CertificationsTab({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.language = 'vi',
  });

  final List<CertificationModel> items;
  final VoidCallback onAdd;
  final ValueChanged<CertificationModel> onEdit;
  final ValueChanged<String> onDelete;
  final String language;

  @override
  Widget build(BuildContext context) {
    final isEn = language == 'en';
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            key: const Key('certifications-empty-state'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primarySlate.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  size: 38,
                  color: AppTheme.primarySlate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEn ? 'Certifications' : 'Chứng chỉ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'This section only appears on the CV after you add one.'
                    : 'Mục này chỉ hiện trên CV khi bạn thêm chứng chỉ.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(isEn ? 'Add certification' : 'Thêm chứng chỉ'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...items.map(
          (item) => Card(
            child: ListTile(
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (item.score?.isNotEmpty == true) item.score!,
                  item.issuer,
                ].where((e) => e.isNotEmpty).join(' • '),
              ),
              onTap: () => onEdit(item),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(item.id),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(isEn ? 'Add another certification' : 'Thêm chứng chỉ'),
        ),
      ],
    );
  }
}
