import 'package:cv_maker_mobile/core/constants/env_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(dotenv.clean);

  test('secondary profile is selected explicitly', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_ACTIVE_PROFILE=secondary
SUPABASE_PRIMARY_URL=https://primary.supabase.co
SUPABASE_PRIMARY_ANON_KEY=primary-key
SUPABASE_SECONDARY_URL=https://secondary.supabase.co
SUPABASE_SECONDARY_ANON_KEY=secondary-key
''',
    );

    expect(EnvConstants.supabaseUrl, 'https://secondary.supabase.co');
    expect(EnvConstants.supabaseAnonKey, 'secondary-key');
    expect(EnvConstants.supabaseProfileLabel, 'Project phụ');
    expect(EnvConstants.isSupabaseConfigured, isTrue);
  });

  test('legacy one-project configuration remains supported', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_URL=https://legacy.supabase.co
SUPABASE_ANON_KEY=legacy-key
''',
    );

    expect(EnvConstants.supabaseUrl, 'https://legacy.supabase.co');
    expect(EnvConstants.supabaseProfileLabel, 'Project mặc định');
    expect(EnvConstants.isSupabaseConfigured, isTrue);
  });

  test('explicit invalid profile does not silently switch projects', () {
    dotenv.loadFromString(
      envString: '''
SUPABASE_ACTIVE_PROFILE=primary
SUPABASE_PRIMARY_URL=
SUPABASE_PRIMARY_ANON_KEY=
SUPABASE_SECONDARY_URL=https://secondary.supabase.co
SUPABASE_SECONDARY_ANON_KEY=secondary-key
''',
    );

    expect(EnvConstants.supabaseProfileLabel, 'Project chính');
    expect(EnvConstants.isSupabaseConfigured, isFalse);
  });
}
