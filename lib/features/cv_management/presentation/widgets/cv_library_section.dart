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

  bool get _isCustomized =>
      _filter != CvLibraryFilter.all || _sort != CvLibrarySort.recentlyUpdated;

  static const _filterLabels = {
    CvLibraryFilter.all: 'Tất cả',
    CvLibraryFilter.cloud: 'Đã sao lưu',
    CvLibraryFilter.local: 'Trên máy',
    CvLibraryFilter.incomplete: 'Cần hoàn thiện',
  };

  static const _sortLabels = {
    CvLibrarySort.recentlyUpdated: 'Mới cập nhật',
    CvLibrarySort.oldestUpdated: 'Cũ nhất',
    CvLibrarySort.title: 'Tên A–Z',
    CvLibrarySort.completion: 'Hoàn thiện nhất',
  };

  Future<void> _openOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget chips<T>(
            Map<T, String> labels,
            T selected,
            ValueChanged<T> onPick,
          ) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in labels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: entry.key == selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      onPick(entry.key);
                      setSheetState(() {});
                    },
                  ),
              ],
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                key: const Key('cv-library-options-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  chips(
                    _filterLabels,
                    _filter,
                    (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sắp xếp',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  chips(
                    _sortLabels,
                    _sort,
                    (value) => setState(() => _sort = value),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    // Search and filters only help once the library grows.
    final showTools = widget.items.length > 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTools) ...[
          TextField(
            key: const Key('cv-library-search'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm CV',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Xoá',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  IconButton(
                    key: const Key('cv-library-options'),
                    tooltip: 'Lọc và sắp xếp',
                    onPressed: _openOptions,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: _isCustomized ? AppTheme.brandIndigo : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
              maxCrossAxisExtent: 520,
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
