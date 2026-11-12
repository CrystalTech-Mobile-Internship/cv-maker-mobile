import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/legal_documents.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final document = LegalDocuments.of(type);
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'Cập nhật ngày ${document.updatedOn}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(document.intro, style: const TextStyle(height: 1.5)),
                for (final section in document.sections) ...[
                  const SizedBox(height: 20),
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final paragraph in section.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        paragraph,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                Text(
                  AppConstants.supportEmail.isEmpty
                      ? 'Liên hệ: dùng email hỗ trợ ghi trên trang tải ứng dụng.'
                      : 'Liên hệ: ${AppConstants.supportEmail}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Điều khoản sử dụng · Chính sách bảo mật" links for footers and forms.
class LegalLinksText extends StatelessWidget {
  const LegalLinksText({super.key, this.prefix = '', this.textAlign});

  final String prefix;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppTheme.brandIndigo,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12.5,
          color: AppTheme.mutedText,
          height: 1.4,
        ),
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(
            text: 'Điều khoản sử dụng',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          const TextSpan(text: ' và '),
          TextSpan(
            text: 'Chính sách bảo mật',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
