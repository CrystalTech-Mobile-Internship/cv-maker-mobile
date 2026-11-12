import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Entry point for AI-assisted CV creation on the dashboard.
class AiAssistantCard extends StatelessWidget {
  const AiAssistantCard({
    super.key,
    required this.onChat,
    required this.onImport,
    this.onPractice,
  });

  final VoidCallback onChat;
  final VoidCallback onImport;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.indigoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.brandIndigo,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ lý AI tạo CV',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Trò chuyện để AI soạn CV, hoặc tải CV cũ lên để AI đọc giúp.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const ValueKey('open-ai-interview'),
                  onPressed: onChat,
                  child: const Text('Trò chuyện tạo CV'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onImport,
                  child: const Text('Tải CV PDF/Word'),
                ),
              ),
            ],
          ),
          if (onPractice != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('open-interview-practice'),
                onPressed: onPractice,
                child: const Text('Luyện phỏng vấn với AI theo CV của bạn'),
              ),
            ),
        ],
      ),
    );
  }
}
