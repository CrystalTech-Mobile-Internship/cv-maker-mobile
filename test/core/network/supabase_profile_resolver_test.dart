import 'package:cv_maker_mobile/core/constants/env_constants.dart';
import 'package:cv_maker_mobile/core/network/supabase_profile_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const _primary = SupabaseEnvironment(
  name: 'primary',
  label: 'Project chính',
  url: 'https://primary.supabase.co',
  anonKey: 'sb_publishable_primary',
);
const _secondary = SupabaseEnvironment(
  name: 'secondary',
  label: 'Project phụ',
  url: 'https://secondary.supabase.co',
  anonKey: 'sb_publishable_secondary',
);

SupabaseHealthProbe _healthy(Set<String> up) =>
    (env) async => up.contains(env.name);

void main() {
  test('keeps the preferred project when it is healthy', () async {
    final result = await SupabaseProfileResolver.resolve(
      preferred: _primary,
      fallback: _secondary,
      probe: _healthy({'primary', 'secondary'}),
    );
    expect(result.environment?.name, 'primary');
    expect(result.usedFallback, isFalse);
  });

  test('fails over when the preferred project is unreachable', () async {
    final result = await SupabaseProfileResolver.resolve(
      preferred: _primary,
      fallback: _secondary,
      probe: _healthy({'secondary'}),
    );
    expect(result.environment?.name, 'secondary');
    expect(result.usedFallback, isTrue);
  });

  test('stays on the preferred project when both are offline', () async {
    final result = await SupabaseProfileResolver.resolve(
      preferred: _primary,
      fallback: _secondary,
      probe: (env) => throw Exception('offline'),
    );
    expect(result.environment?.name, 'primary');
    expect(result.usedFallback, isFalse);
  });

  test('does not probe without a fallback', () async {
    var probes = 0;
    final result = await SupabaseProfileResolver.resolve(
      preferred: _primary,
      probe: (env) async {
        probes++;
        return false;
      },
    );
    expect(result.environment?.name, 'primary');
    expect(probes, 0);
  });
}
