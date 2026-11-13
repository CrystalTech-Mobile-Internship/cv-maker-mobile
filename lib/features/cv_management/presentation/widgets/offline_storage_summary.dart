import 'package:flutter/material.dart';

class OfflineStorageSummary extends StatelessWidget {
  const OfflineStorageSummary({
    super.key,
    required this.localCount,
    required this.pendingSyncCount,
  });

  final int localCount;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.offline_bolt_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$localCount CV trên máy • '
              '$pendingSyncCount chưa sao lưu',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
