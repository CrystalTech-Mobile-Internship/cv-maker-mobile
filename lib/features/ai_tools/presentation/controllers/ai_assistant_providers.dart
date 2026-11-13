import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_ai_assistant_repository.dart';
import '../../data/services/ai_consent_service.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import 'summary_polish_controller.dart' show aiWritingRemoteDataSourceProvider;

/// Latest daily AI credit budget reported by the server (null until the
/// first AI call or quota refresh in this session).
final aiQuotaProvider = StateProvider<AiQuota?>((ref) => null);

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return SupabaseAiAssistantRepository(
    ref.watch(aiWritingRemoteDataSourceProvider),
    onQuota: (quota) => ref.read(aiQuotaProvider.notifier).state = quota,
  );
});

final aiConsentServiceProvider = Provider<AiConsentService>(
  (ref) => const AiConsentService(),
);
