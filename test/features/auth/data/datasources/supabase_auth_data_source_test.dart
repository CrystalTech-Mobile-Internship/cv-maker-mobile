import 'package:cv_maker_mobile/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile auth callback uses a standards-compliant URI scheme', () {
    final callback = Uri.parse(SupabaseAuthDataSource.callbackUri);

    expect(callback.scheme, 'com.example.cvmakermobile');
    expect(callback.host, 'login-callback');
    expect(callback.path, isEmpty);
  });
}
