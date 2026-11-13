import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_sheet.dart';

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
    return showAppSheet<void>(
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
          AppSheetHandle(margin: const EdgeInsets.only(top: 12, bottom: 8)),

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
                            : 'Vừa 1 trang A4',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isEnglish
                            ? 'Adjust font scale to fit your CV comfortably on A4'
                            : 'Chỉnh cỡ chữ để CV vừa trang',
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
                    widget.isEnglish ? 'Recommended Presets' : 'Chọn nhanh',
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
                    iconColor: AppTheme.brandIndigo,
                    title: widget.isEnglish
                        ? 'Auto-Fit 1 Page A4 (85%)'
                        : 'Gọn 1 trang (85%)',
                    subtitle: widget.isEnglish
                        ? 'Best for freshers and candidates under 5 years experience'
                        : 'Hợp với sinh viên và người dưới 5 năm kinh nghiệm',
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
                        : 'Tiêu chuẩn (100%)',
                    subtitle: widget.isEnglish
                        ? 'Standard font hierarchy for balanced A4 documents'
                        : 'Cỡ chữ thông thường',
                    scaleValue: 1.0,
                    isSelected: (percent == 100),
                  ),
                  const SizedBox(height: 8),

                  // Preset 3: Spacious 115%
                  _buildPresetCard(
                    icon: Icons.zoom_in_rounded,
                    iconColor: AppTheme.brandIndigo,
                    title: widget.isEnglish
                        ? 'Spacious / Large (115%)'
                        : 'Thoáng, dễ đọc (115%)',
                    subtitle: widget.isEnglish
                        ? 'Ideal if you have concise content and want to fill white space'
                        : 'Khi nội dung ngắn, giúp trang không bị trống',
                    scaleValue: 1.15,
                    isSelected: (percent == 115),
                  ),

                  const SizedBox(height: 20),

                  // Manual Slider
                  Text(
                    widget.isEnglish ? 'Manual Fine-Tuning' : 'Tự chỉnh',
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
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.softBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppTheme.mutedText,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isEnglish
                                ? 'Tip: keep a student or junior CV to one page. 85–90% usually fits.'
                                : 'Mẹo: CV của sinh viên nên gọn trong 1 trang. Mức 85–90% thường vừa đủ.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppTheme.primarySlate,
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
