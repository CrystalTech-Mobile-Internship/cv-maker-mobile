import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Modal bottom sheet allowing users to auto-fit their CV to 1 Page A4
/// or choose standard density presets with ATS advice.
class CvPageFitSheet extends StatefulWidget {
  const CvPageFitSheet({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
    this.isEnglish = false,
  });

  final double currentScale;
  final ValueChanged<double> onScaleChanged;
  final bool isEnglish;

  static Future<void> show({
    required BuildContext context,
    required double currentScale,
    required ValueChanged<double> onScaleChanged,
    bool isEnglish = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CvPageFitSheet(
        currentScale: currentScale,
        onScaleChanged: onScaleChanged,
        isEnglish: isEnglish,
      ),
    );
  }

  @override
  State<CvPageFitSheet> createState() => _CvPageFitSheetState();
}

class _CvPageFitSheetState extends State<CvPageFitSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
  }

  void _applyScale(double value) {
    setState(() => _scale = value);
    widget.onScaleChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_scale * 100).round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                    Icons.auto_fix_high_rounded,
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
                        widget.isEnglish
                            ? 'Page Fit & Layout Optimizer'
                            : 'Tối ưu bố cục & Căn chỉnh 1 trang',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isEnglish
                            ? 'Adjust font scale to fit your CV comfortably on A4'
                            : 'Tùy chỉnh tỷ lệ chữ để vừa vặn trang A4 hoàn hảo',
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

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fast Presets
                  Text(
                    widget.isEnglish
                        ? 'Recommended Presets'
                        : 'Tùy chọn nhanh đề xuất',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primarySlate,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Preset 1: Auto 1-Page
                  _buildPresetCard(
                    icon: Icons.electric_bolt_rounded,
                    iconColor: Colors.amber.shade800,
                    title: widget.isEnglish
                        ? 'Auto-Fit 1 Page A4 (85%)'
                        : '⚡ Tự động căn 1 trang A4 (85%)',
                    subtitle: widget.isEnglish
                        ? 'Best for freshers and candidates under 5 years experience'
                        : 'Lý tưởng cho Fresher và ứng viên dưới 5 năm kinh nghiệm',
                    scaleValue: 0.85,
                    isSelected: (percent == 85),
                  ),
                  const SizedBox(height: 8),

                  // Preset 2: Standard 100%
                  _buildPresetCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppTheme.brandIndigo,
                    title: widget.isEnglish
                        ? 'Standard Format (100%)'
                        : '📄 Định dạng tiêu chuẩn (100%)',
                    subtitle: widget.isEnglish
                        ? 'Standard font hierarchy for balanced A4 documents'
                        : 'Cỡ chữ chuẩn theo quy cách quốc tế cân đối trang',
                    scaleValue: 1.0,
                    isSelected: (percent == 100),
                  ),
                  const SizedBox(height: 8),

                  // Preset 3: Spacious 115%
                  _buildPresetCard(
                    icon: Icons.zoom_in_rounded,
                    iconColor: Colors.teal,
                    title: widget.isEnglish
                        ? 'Spacious / Large (115%)'
                        : '🔍 Thoáng đãng / Dễ đọc (115%)',
                    subtitle: widget.isEnglish
                        ? 'Ideal if you have concise content and want to fill white space'
                        : 'Phù hợp khi nội dung ngắn gọn muốn lấp đầy trang đẹp',
                    scaleValue: 1.15,
                    isSelected: (percent == 115),
                  ),

                  const SizedBox(height: 20),

                  // Manual Slider
                  Text(
                    widget.isEnglish
                        ? 'Manual Fine-Tuning'
                        : 'Tinh chỉnh tỷ lệ thủ công',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primarySlate,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isEnglish
                                  ? 'Font Scale:'
                                  : 'Tỷ lệ cỡ chữ:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brandIndigo.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandIndigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _scale,
                          min: 0.75,
                          max: 1.40,
                          divisions: 13,
                          activeColor: AppTheme.brandIndigo,
                          onChanged: _applyScale,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ATS Advice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isEnglish
                                ? 'Recruiter Tip: 80% of hiring managers prefer a crisp 1-page resume for juniors. Use 85% scale to prevent 1-2 orphan lines spilling onto page 2.'
                                : 'Mẹo từ nhà tuyển dụng: 80% HR thích CV đúng 1 trang A4 cho sinh viên/Fresher. Hãy dùng mức 85%–90% để tránh rớt 1–2 dòng lẻ loi sang trang 2.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double scaleValue,
    required bool isSelected,
  }) {
    return InkWell(
      key: Key('preset-${(scaleValue * 100).round()}'),
      onTap: () => _applyScale(scaleValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandIndigo.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandIndigo : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.brandIndigo : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.brandIndigo,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
