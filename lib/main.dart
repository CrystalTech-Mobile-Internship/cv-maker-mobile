import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'features/auth/data/guest_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
      'ℹ️ [Main] Không tìm thấy file .env hoặc đang dùng cấu hình mặc định: $e',
    );
  }

  // Initialize Supabase if keys are provided
  await SupabaseService.initialize();
  final startInGuestMode = await const GuestSessionService().isGuestMode();
  final startAuthenticated =
      SupabaseService.client?.auth.currentSession != null;

  // Run app inside Riverpod ProviderScope
  runApp(
    ProviderScope(
      child: CvMakerApp(
        startInGuestMode: startInGuestMode,
        startAuthenticated: startAuthenticated,
      ),
    ),
  );
}
