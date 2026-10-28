import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/services/cv_completion_service.dart';

enum CvLibraryFilter { all, cloud, local, incomplete }

enum CvLibrarySort { recentlyUpdated, oldestUpdated, title, completion }

class CvLibrarySection extends StatefulWidget {
  const CvLibrarySection({
    super.key,
    required this.items,
    required this.isDesktop,
    required this.itemBuilder,
  });

  final List<CvModel> items;
  final bool isDesktop;
  final Widget Function(BuildContext context, CvModel cv) itemBuilder;

  @override
  State<CvLibrarySection> createState() => _CvLibrarySectionState();
}

class _CvLibrarySectionState extends State<CvLibrarySection> {
  final _searchController = TextEditingController();
  String _query = '';
  CvLibraryFilter _filter = CvLibraryFilter.all;
  CvLibrarySort _sort = CvLibrarySort.recentlyUpdated;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CvModel> get _visibleItems {
    final normalizedQuery = _query.trim().toLowerCase();
    final result = widget.items
        .where((cv) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              cv.title.toLowerCase().contains(normalizedQuery) ||
              cv.personalInfo.targetRole.toLowerCase().contains(
                normalizedQuery,
              );
          if (!matchesQuery) return false;
          final completion = CvCompletionService.evaluate(cv).percentage;
          return switch (_filter) {
            CvLibraryFilter.all => true,
            CvLibraryFilter.cloud => cv.isSynced,
            CvLibraryFilter.local => !cv.isSynced,
            CvLibraryFilter.incomplete => completion < 100,
          };
        })
        .toList(growable: false);

    result.sort((left, right) {
      return switch (_sort) {
        CvLibrarySort.recentlyUpdated => right.updatedAt.compareTo(
          left.updatedAt,
        ),
        CvLibrarySort.oldestUpdated => left.updatedAt.compareTo(
          right.updatedAt,
        ),
        CvLibrarySort.title => left.title.toLowerCase().compareTo(
          right.title.toLowerCase(),
        ),
        CvLibrarySort.completion => CvCompletionService.evaluate(
          right,
        ).percentage.compareTo(CvCompletionService.evaluate(left).percentage),
      };
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('cv-library-search'),
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên CV hoặc vị trí ứng tuyển',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xoá tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactDropdown<CvLibraryFilter>(
                key: const Key('cv-library-filter'),
                value: _filter,
                icon: Icons.filter_alt_outlined,
                items: const {
                  CvLibraryFilter.all: 'Tất cả',
                  CvLibraryFilter.cloud: 'Đã lên Cloud',
                  CvLibraryFilter.local: 'Trên máy',
                  CvLibraryFilter.incomplete: 'Cần hoàn thiện',
                },
                onChanged: (value) => setState(() => _filter = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactDropdown<CvLibrarySort>(
                key: const Key('cv-library-sort'),
                value: _sort,
                icon: Icons.sort_rounded,
                items: const {
                  CvLibrarySort.recentlyUpdated: 'Mới cập nhật',
                  CvLibrarySort.oldestUpdated: 'Cũ cập nhật',
                  CvLibrarySort.title: 'Tên A–Z',
                  CvLibrarySort.completion: 'Hoàn thiện nhất',
                },
                onChanged: (value) => setState(() => _sort = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _NoLibraryResult(onReset: _reset)
        else if (!widget.isDesktop)
          Column(
            children: items
                .map(
                  (cv) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: widget.itemBuilder(context, cv),
                  ),
                )
                .toList(growable: false),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 238,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                widget.itemBuilder(context, items[index]),
          ),
      ],
    );
  }

  void _reset() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = CvLibraryFilter.all;
      _sort = CvLibrarySort.recentlyUpdated;
    });
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    super.key,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final IconData icon;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              child: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _NoLibraryResult extends StatelessWidget {
  const _NoLibraryResult({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('cv-library-empty-result'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.manage_search_rounded,
            size: 38,
            color: AppTheme.primarySlate,
          ),
          const SizedBox(height: 8),
          const Text(
            'Không tìm thấy CV phù hợp',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onReset, child: const Text('Xoá bộ lọc')),
        ],
      ),
    );
  }
}
