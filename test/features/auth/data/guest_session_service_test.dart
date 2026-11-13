import 'package:cv_maker_mobile/features/auth/data/guest_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guest mode is disabled by default', () async {
    const service = GuestSessionService();

    expect(await service.isGuestMode(), isFalse);
  });

  test('guest choice persists for the next app launch', () async {
    const service = GuestSessionService();

    await service.setGuestMode(true);
    expect(await service.isGuestMode(), isTrue);

    await service.setGuestMode(false);
    expect(await service.isGuestMode(), isFalse);
  });
}
