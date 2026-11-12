import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../domain/services/cv_action_verbs_service.dart';

/// Interactive modal sheet that presents candidates with standard ATS Action Verbs
/// and Google XYZ formula examples to boost bullet-point impact.
class AtsActionVerbsSheet extends StatefulWidget {
  const AtsActionVerbsSheet({
    super.key,
    required this.language,
    this.onInsertVerb,
  });

  final String language;
  final ValueChanged<String>? onInsertVerb;

  static Future<void> show({
    required BuildContext context,
    required String language,
    ValueChanged<String>? onInsertVerb,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AtsActionVerbsSheet(language: language, onInsertVerb: onInsertVerb),
    );
  }

  @override
  State<AtsActionVerbsSheet> createState() => _AtsActionVerbsSheetState();
}

class _AtsActionVerbsSheetState extends State<AtsActionVerbsSheet> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  bool get _isEn => widget.language == 'en';

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEn
              ? 'Copied $label to clipboard'
              : 'Đã sao chép $label vào bộ nhớ tạm',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allVerbs = CvActionVerbsService.getByCategory(_selectedCategory);
    final filtered = allVerbs.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.verbVi.toLowerCase().contains(q) ||
          item.verbEn.toLowerCase().contains(q) ||
          item.contextVi.toLowerCase().contains(q) ||
          item.contextEn.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEn
                            ? 'ATS Action Verbs & Formulas'
                            : 'Ngân hàng từ khóa hành động ATS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEn
                            ? 'Google XYZ Formula: Accomplished [X], measured by [Y], by doing [Z]'
                            : 'Công thức Google XYZ: Đạt được [X], đo bằng [Y], thông qua [Z]',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: _isEn
                    ? 'Search action verbs...'
                    : 'Tìm từ khóa hành động...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Category Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip('all', _isEn ? 'All Verbs' : 'Tất cả'),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'engineering',
                  _isEn ? 'Engineering' : 'Kỹ thuật / Code',
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'optimization',
                  _isEn ? 'Optimization' : 'Tối ưu / Hiệu năng',
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'leadership',
                  _isEn ? 'Leadership' : 'Lãnh đạo / Điều phối',
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  'analysis',
                  _isEn ? 'Analysis' : 'Phân tích / Đánh giá',
                ),
              ],
            ),
          ),

          const Divider(height: 12),

          // Verbs List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _isEn
                          ? 'No verbs match your search'
                          : 'Không có từ khóa phù hợp',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final verbText = item.verb(widget.language);
                      final contextText = item.context(widget.language);
                      final exampleText = item.example(widget.language);

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      verbText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      contextText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  if (widget.onInsertVerb != null)
                                    FilledButton.tonal(
                                      key: Key('insert-verb-${item.verbVi}'),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                      onPressed: () {
                                        widget.onInsertVerb!(verbText);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(_isEn ? 'Insert' : 'Chèn'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Example Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.format_quote_rounded,
                                          size: 14,
                                          color: AppTheme.brandIndigo,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isEn
                                              ? 'Example (Formula XYZ):'
                                              : 'Ví dụ chuẩn công thức XYZ:',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () => _copyToClipboard(
                                            exampleText,
                                            _isEn ? 'Example' : 'Ví dụ',
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.copy_rounded,
                                                  size: 12,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  _isEn ? 'Copy' : 'Sao chép',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exampleText,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.deepOrange,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      onSelected: (_) => setState(() => _selectedCategory = id),
    );
  }
}
