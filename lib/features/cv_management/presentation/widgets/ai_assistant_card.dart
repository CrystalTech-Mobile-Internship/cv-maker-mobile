import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../ai_tools/domain/models/ai_assistant_models.dart';
import 'side_panel_card.dart';

/// Quick ways to start a CV: chat, or read an existing file.
class AiAssistantCard extends StatelessWidget {
  const AiAssistantCard({
    super.key,
    required this.onChat,
    required this.onImport,
  });

  final VoidCallback onChat;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SidePanelCard(
      title: tr('Tạo CV nhanh', 'Quick start'),
      subtitle: tr(
        'Trả lời vài câu hỏi hoặc dùng CV có sẵn.',
        'Answer a few questions or use a CV you have.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const ValueKey('open-ai-interview'),
            onPressed: onChat,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandIndigo,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: shape,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(tr('Trò chuyện tạo CV', 'Chat to build a CV')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onImport,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: shape,
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: Text(
              tr('Dùng CV có sẵn (PDF, Word)', 'Use my CV (PDF, Word)'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              'Trò chuyện: ${AiCreditCost.interview} lượt AI mỗi tin, '
                  '${AiCreditCost.generateCv} lượt khi tạo CV. '
                  'Đọc CV có sẵn: miễn phí hoặc ${AiCreditCost.parseResume} lượt '
                  'nếu đọc kỹ.',
              'Chat: ${AiCreditCost.interview} AI use per message, '
                  '${AiCreditCost.generateCv} to create the CV. '
                  'Reading your CV: free, or ${AiCreditCost.parseResume} uses '
                  'for a careful read.',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
