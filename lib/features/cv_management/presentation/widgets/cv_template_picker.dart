import 'package:flutter/material.dart';

import '../../../cv_editor/domain/models/cv_template.dart';

class CvTemplatePicker extends StatelessWidget {
  const CvTemplatePicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.isPro = false,
  });

  final bool isPro;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final available = CvTemplateCatalog.available(isPro: isPro);
    final templates = [
      ...available.where((template) => template.id == selectedId),
      ...available.where((template) => template.id != selectedId),
    ];
    return Column(
      children: templates
          .map((template) {
            final isSelected = template.id == selectedId;
            final foreground = isSelected
                ? Colors.white
                : colorScheme.onSurface;
            final secondaryForeground = isSelected
                ? Colors.white.withValues(alpha: 0.82)
                : colorScheme.onSurfaceVariant;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(template.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.description_outlined,
                        size: 22,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ).copyWith(color: foreground),
                            ),
                            Text(
                              template.audience,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: secondaryForeground),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected || template.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.16)
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isSelected ? 'ĐÃ CHỌN' : 'Pro',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
