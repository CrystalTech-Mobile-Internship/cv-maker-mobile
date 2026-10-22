import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import 'template_thumbnail.dart';

enum TemplateFilter { all, photo, noPhoto, premium }

class TemplateCatalogView extends StatefulWidget {
  const TemplateCatalogView({
    super.key,
    required this.onUseTemplate,
    required this.onPremiumTap,
  });

  final ValueChanged<CvTemplate> onUseTemplate;
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverList.list(
            children: [
              _CatalogIntro(freeCount: CvTemplateCatalog.freeTemplates.length),
              const SizedBox(height: 14),
              _PremiumBanner(onTap: () => _setFilter(TemplateFilter.premium)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Tất cả', TemplateFilter.all),
                    _filterChip('Có ảnh', TemplateFilter.photo),
                    _filterChip('Không ảnh', TemplateFilter.noPhoto),
                    _filterChip('Premium', TemplateFilter.premium),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              mainAxisExtent: 342,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                onTap: () => template.isPremium
                    ? widget.onPremiumTap(template)
                    : widget.onUseTemplate(template),
              );
            }, childCount: templates.length),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, TemplateFilter value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: _filter == value,
        label: Text(label),
        showCheckmark: false,
        avatar: value == TemplateFilter.premium
            ? const Icon(Icons.workspace_premium_rounded, size: 17)
            : null,
        onSelected: (_) => _setFilter(value),
      ),
    );
  }

  void _setFilter(TemplateFilter value) {
    setState(() => _filter = value);
  }
}

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro({required this.freeCount});

  final int freeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn phong cách của bạn',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$freeCount mẫu miễn phí • Xem trước trực quan',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.auto_awesome, color: AppTheme.brandIndigo),
        ),
      ],
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF312E81),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFDE68A),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium & AI sắp ra mắt',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nhiều mẫu hơn • Gợi ý nội dung thông minh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Color(0xFFDDE2FF)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final CvTemplate template;
  final VoidCallback onTap;

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: template.isPremium
                          ? OutlinedButton.icon(
                              onPressed: onTap,
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                              ),
                              label: const Text('Sắp ra mắt'),
                            )
                          : FilledButton(
                              onPressed: onTap,
                              child: const Text('Dùng mẫu'),
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
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}
