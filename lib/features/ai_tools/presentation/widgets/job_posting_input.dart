import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/ai_assistant_providers.dart';
import 'ai_access_guard.dart';

final _urlPattern = RegExp(r'^https?://\S+$', caseSensitive: false);

/// True when [input] is a single web link rather than pasted text.
bool looksLikeJobLink(String input) => _urlPattern.hasMatch(input.trim());

/// Returns the job posting text for [input]: pasted text as is, or the
/// content of the page when [input] is a link. Returns null (after telling
/// the user why) when the text could not be obtained.
Future<String?> resolveJobPostingInput(
  BuildContext context,
  WidgetRef ref,
  String input, {
  String redirectPath = '/home',
}) async {
  final value = input.trim();
  void toast(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
  if (!looksLikeJobLink(value)) {
    if (value.length < 20) {
      toast('Hãy dán link hoặc nội dung tin tuyển dụng.');
      return null;
    }
    return value;
  }
  if (!await ensureAiAccess(context, ref, redirectPath: redirectPath)) {
    return null;
  }
  if (!context.mounted) return null;
  try {
    return await runWithAiProgress(
      context,
      'Đang đọc tin tuyển dụng...',
      () => ref.read(aiAssistantRepositoryProvider).fetchJobPosting(value),
    );
  } on AiWritingFailure catch (failure) {
    if (context.mounted) toast(failure.message);
    return null;
  }
}
