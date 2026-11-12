import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import 'template_thumbnail.dart';

enum TemplateFilter { all, photo, noPhoto, premium }

class TemplateCatalogView extends StatefulWidget {
  const TemplateCatalogView({
    super.key,
    required this.onUseTemplate,
    required this.onPreviewTemplate,
    required this.onPremiumTap,
    this.isPro = false,
  });

  /// Pro accounts can use premium templates like any other template.
  final bool isPro;
  final ValueChanged<CvTemplate> onUseTemplate;
  final ValueChanged<CvTemplate> onPreviewTemplate;
  final ValueChanged<CvTemplate> onPremiumTap;

  @override
  State<TemplateCatalogView> createState() => _TemplateCatalogViewState();
}

class _TemplateCatalogViewState extends State<TemplateCatalogView> {
  TemplateFilter _filter = TemplateFilter.all;

  List<CvTemplate> get _visibleTemplates {
    return switch (_filter) {
      TemplateFilter.all => CvTemplateCatalog.allTemplates,
      TemplateFilter.photo =>
        CvTemplateCatalog.allTemplates
            .where((template) => template.hasPhoto)
            .toList(growable: false),
      TemplateFilter.noPhoto =>
        CvTemplateCatalog.allTemplates
            .where((template) => !template.hasPhoto)
            .toList(growable: false),
      TemplateFilter.premium => CvTemplateCatalog.premiumTemplates,
    };
  }

  @override
  Widget build(BuildContext context) {
    final templates = _visibleTemplates;
    return CustomScrollView(
      key: const PageStorageKey('template-catalog'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          sliver: SliverList.list(
            children: [
              _CatalogHeader(
                templateCount: CvTemplateCatalog.allTemplates.length,
              ),
              const SizedBox(height: 10),
              _TemplateFilterBar(selected: _filter, onSelected: _setFilter),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 380,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final template = templates[index];
              final locked = template.isPremium && !widget.isPro;
              return _TemplateCard(
                template: template,
                locked: locked,
                onPreview: locked
                    ? null
                    : () => widget.onPreviewTemplate(template),
                onTap: () => locked
                    ? widget.onPremiumTap(template)
                    : widget.onUseTemplate(template),
              );
            }, childCount: templates.length),
          ),
        ),
      ],
    );
  }

  void _setFilter(TemplateFilter value) {
    setState(() => _filter = value);
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.templateCount});

  final int templateCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Chọn mẫu CV',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
        const Spacer(),
        Text(
          '$templateCount mẫu',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TemplateFilterBar extends StatelessWidget {
  const _TemplateFilterBar({required this.selected, required this.onSelected});

  final TemplateFilter selected;
  final ValueChanged<TemplateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (TemplateFilter.all, 'Tất cả'),
      (TemplateFilter.photo, 'Có ảnh'),
      (TemplateFilter.noPhoto, 'Không ảnh'),
      (TemplateFilter.premium, 'Premium'),
    ];
    return Container(
      key: const Key('template-filter-row'),
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: filters
            .map((filter) {
              final isSelected = selected == filter.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Material(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      key: ValueKey('template-filter-${filter.$1.name}'),
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => onSelected(filter.$1),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            filter.$2,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.brandIndigo
                                  : AppTheme.mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onPreview,
    this.locked = false,
  });

  final CvTemplate template;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: TemplateThumbnail(template: template),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _StatusBadge(template: template),
                    ),
                    if (template.isPremium)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0x660F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.brandIndigo,
                                child: Icon(Icons.lock_rounded, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.audience,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: locked
                          ? OutlinedButton(
                              onPressed: onTap,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF9A3412),
                                backgroundColor: const Color(0xFFFFF7ED),
                                side: const BorderSide(
                                  color: Color(0xFFEA580C),
                                  width: 1.4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Gói Pro',
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 46,
                                  child: OutlinedButton(
                                    key: ValueKey(
                                      'preview-template-${template.id}',
                                    ),
                                    onPressed: onPreview,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: onTap,
                                    style: AppTheme.createCvButton.copyWith(
                                      padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 6),
                                      ),
                                      textStyle: const WidgetStatePropertyAll(
                                        TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Dùng mẫu'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.template});

  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final label = template.isPremium
        ? 'PREMIUM'
        : template.isNew
        ? 'MỚI'
        : 'FREE';
    final background = template.isPremium
        ? const Color(0xFFFFF7D6)
        : template.isNew
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFEEF2FF);
    final foreground = template.isPremium
        ? const Color(0xFF92400E)
        : template.isNew
        ? const Color(0xFF166534)
        : AppTheme.brandIndigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 4)],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}
