import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/skill_model.dart';
import '../../domain/services/cv_skill_catalog_service.dart';

/// Modal sheet that allows users to quickly browse and pick skills from curated domain lists.
class SkillBankSheet extends StatefulWidget {
  const SkillBankSheet({
    super.key,
    required this.existingSkills,
    required this.onAddSkill,
    this.language = 'vi',
  });

  final List<SkillModel> existingSkills;
  final ValueChanged<SkillModel> onAddSkill;
  final String language;

  static Future<void> show({
    required BuildContext context,
    required List<SkillModel> existingSkills,
    required ValueChanged<SkillModel> onAddSkill,
    String language = 'vi',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SkillBankSheet(
        existingSkills: existingSkills,
        onAddSkill: onAddSkill,
        language: language,
      ),
    );
  }

  @override
  State<SkillBankSheet> createState() => _SkillBankSheetState();
}

class _SkillBankSheetState extends State<SkillBankSheet> {
  String _selectedDomainId = 'all';
  String _searchQuery = '';
  final Set<String> _addedNames = {};

  bool get _isEn => widget.language == 'en';

  @override
  void initState() {
    super.initState();
    for (final s in widget.existingSkills) {
      _addedNames.add(s.name.trim().toLowerCase());
    }
  }

  bool _isSkillAdded(String name) {
    return _addedNames.contains(name.trim().toLowerCase());
  }

  void _handleAddSkill(SkillRecommendation item) {
    final newSkill = SkillModel(
      id: 'skill-${DateTime.now().microsecondsSinceEpoch}',
      name: item.name,
      category: item.category,
      proficiency: item.defaultProficiency,
    );
    setState(() {
      _addedNames.add(item.name.trim().toLowerCase());
    });
    widget.onAddSkill(newSkill);
  }

  @override
  Widget build(BuildContext context) {
    final allGroups = CvSkillCatalogService.groups;
    final List<SkillRecommendation> displayedSkills;

    if (_selectedDomainId == 'all') {
      displayedSkills = allGroups.expand((g) => g.skills).toList();
    } else {
      displayedSkills = CvSkillCatalogService.findSuggestionsByDomain(
        _selectedDomainId,
      );
    }

    final filteredSkills = displayedSkills.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.brandIndigo,
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
                            ? 'Skill Bank & Suggestions'
                            : 'Thư viện kỹ năng gợi ý',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEn
                            ? 'Tap any skill chip to add it directly to your CV'
                            : 'Chạm vào chip để thêm ngay kỹ năng vào hồ sơ của bạn',
                        style: TextStyle(
                          fontSize: 12,
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

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: _isEn ? 'Search skills...' : 'Tìm kiếm kỹ năng...',
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

          // Domain Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildDomainFilterChip(
                  id: 'all',
                  label: _isEn ? 'All Domains' : 'Tất cả lĩnh vực',
                ),
                for (final g in allGroups)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildDomainFilterChip(
                      id: g.id,
                      label: g.title(widget.language),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Skills Chips Grid
          Expanded(
            child: filteredSkills.isEmpty
                ? Center(
                    child: Text(
                      _isEn
                          ? 'No matching skills found'
                          : 'Không tìm thấy kỹ năng phù hợp',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: filteredSkills.map((item) {
                        final added = _isSkillAdded(item.name);
                        return FilterChip(
                          key: Key('skill-chip-${item.name}'),
                          label: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: added
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: added
                                  ? AppTheme.brandIndigo
                                  : Colors.black87,
                            ),
                          ),
                          avatar: added
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppTheme.brandIndigo,
                                )
                              : const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                          selected: added,
                          selectedColor: AppTheme.brandIndigo.withAlpha(25),
                          backgroundColor: Colors.grey.shade50,
                          side: BorderSide(
                            color: added
                                ? AppTheme.brandIndigo
                                : Colors.grey.shade300,
                          ),
                          onSelected: (selected) {
                            if (!added) {
                              _handleAddSkill(item);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainFilterChip({required String id, required String label}) {
    final isSelected = _selectedDomainId == id;
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
      selectedColor: AppTheme.brandIndigo,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      onSelected: (_) => setState(() => _selectedDomainId = id),
    );
  }
}
