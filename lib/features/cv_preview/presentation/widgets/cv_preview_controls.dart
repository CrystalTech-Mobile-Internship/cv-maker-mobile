import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

/// Compact document toolbar for settings that affect the whole exported CV.
class CvPreviewControls extends StatefulWidget {
  const CvPreviewControls({
    super.key,
    required this.language,
    required this.fontSizeScale,
    required this.showSampleContent,
    required this.onLanguageChanged,
    required this.onFontSizeScaleChanged,
    required this.onSampleContentChanged,
    required this.onResetFormatting,
  });

  final String language;
  final double fontSizeScale;
  final bool showSampleContent;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<double> onFontSizeScaleChanged;
  final ValueChanged<bool> onSampleContentChanged;
  final VoidCallback onResetFormatting;

  @override
  State<CvPreviewControls> createState() => _CvPreviewControlsState();
}

class _CvPreviewControlsState extends State<CvPreviewControls> {
  static const double _minimumScale = 0.75;
  static const double _maximumScale = 1.50;
  static const double _step = 0.05;

  late final TextEditingController _scaleController;
  late final FocusNode _scaleFocusNode;

  bool get _isEnglish => widget.language == 'en';

  @override
  void initState() {
    super.initState();
    _scaleController = TextEditingController(text: _percentageText());
    _scaleFocusNode = FocusNode()..addListener(_handleScaleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CvPreviewControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontSizeScale != widget.fontSizeScale &&
        !_scaleFocusNode.hasFocus) {
      _scaleController.text = _percentageText();
    }
  }

  @override
  void dispose() {
    _scaleFocusNode
      ..removeListener(_handleScaleFocusChanged)
      ..dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _percentageText() => (widget.fontSizeScale * 100).round().toString();

  void _handleScaleFocusChanged() {
    if (!_scaleFocusNode.hasFocus) _applyTypedScale();
  }

  void _applyTypedScale() {
    final percentage = int.tryParse(_scaleController.text);
    if (percentage == null) {
      _scaleController.text = _percentageText();
      return;
    }

    final scale = (percentage / 100).clamp(_minimumScale, _maximumScale);
    _scaleController.text = (scale * 100).round().toString();
    _changeScale(scale);
  }

  void _changeScale(double value) {
    final scale = value.clamp(_minimumScale, _maximumScale);
    if ((scale - widget.fontSizeScale).abs() >= 0.001) {
      widget.onFontSizeScaleChanged(scale);
    }
  }

  void _stepScale(double direction) {
    final stepped =
        ((widget.fontSizeScale + (_step * direction)) * 100).round() / 100;
    _scaleController.text = (stepped * 100).round().toString();
    _changeScale(stepped);
  }

  @override
  Widget build(BuildContext context) {
    final notice = _isEnglish
        ? 'The preview uses the real A4 PDF, including whitespace and page breaks.'
        : 'Hiển thị đúng như khi in ra giấy A4.';

    return Material(
      color: const Color(0xFFF8FAFC),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      _LanguageMenu(
                        language: widget.language,
                        onChanged: widget.onLanguageChanged,
                      ),
                      const _ToolbarDivider(),
                      const Icon(
                        Icons.format_size_rounded,
                        size: 19,
                        color: AppTheme.primarySlate,
                      ),
                      const SizedBox(width: 4),
                      _ToolbarButton(
                        key: const Key('decrease-font-size'),
                        tooltip: _isEnglish
                            ? 'Decrease text size'
                            : 'Giảm cỡ chữ',
                        onPressed: widget.fontSizeScale <= _minimumScale
                            ? null
                            : () => _stepScale(-1),
                        child: const Text(
                          'A−',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 3),
                      _PercentageField(
                        controller: _scaleController,
                        focusNode: _scaleFocusNode,
                        onSubmitted: (_) => _applyTypedScale(),
                        tooltip: _isEnglish
                            ? 'Enter 75–150%'
                            : 'Nhập cỡ chữ từ 75–150%',
                      ),
                      const SizedBox(width: 3),
                      _ToolbarButton(
                        key: const Key('increase-font-size'),
                        tooltip: _isEnglish
                            ? 'Increase text size'
                            : 'Tăng cỡ chữ',
                        onPressed: widget.fontSizeScale >= _maximumScale
                            ? null
                            : () => _stepScale(1),
                        child: const Text(
                          'A+',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      _ToolbarButton(
                        key: const Key('reset-font-size'),
                        tooltip: _isEnglish
                            ? 'Reset document formatting'
                            : 'Khôi phục mặc định',
                        onPressed: widget.onResetFormatting,
                        child: const Icon(Icons.restart_alt_rounded, size: 19),
                      ),
                      Tooltip(
                        message: notice,
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 4),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 19,
                            color: AppTheme.primarySlate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEnglish
                            ? 'Keep headings and examples for empty sections'
                            : 'Hiện nội dung mẫu ở phần còn trống',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      key: const Key('preview-sample-content-toggle'),
                      value: widget.showSampleContent,
                      onChanged: widget.onSampleContentChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.language, required this.onChanged});

  final String language;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 9, right: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('preview-language-menu'),
          value: language,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 19),
          style: const TextStyle(
            color: AppTheme.primarySlate,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'vi', child: Text('VI')),
            DropdownMenuItem(value: 'en', child: Text('EN')),
          ],
          onChanged: (value) {
            if (value != null && value != language) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _PercentageField extends StatelessWidget {
  const _PercentageField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.tooltip,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 62,
        height: 36,
        child: TextField(
          key: const Key('font-size-percentage-field'),
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
          icon: child,
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE2E8F0),
    );
  }
}
