import 'package:flutter/material.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 52),
                const SizedBox(height: 12),
                Text(
                  isEn ? 'No certifications' : 'Chưa có chứng chỉ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isEn
                      ? 'This section only appears on the CV after you add one.'
                      : 'Mục này chỉ hiện trên CV khi bạn thêm chứng chỉ.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isEn ? 'Add certification' : 'Thêm chứng chỉ'),
                ),
              ],
            ),
          )
        else ...[
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
      ],
    );
  }
}
