import 'package:cv_maker_mobile/core/database/app_database.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/local_cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/services/linked_account_cv_adopter.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late LocalCvRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalCvRepository(database);
  });

  tearDown(() => database.close());

  CvModel cv(String id, String? userId) => CvModel.empty(
    id: id,
    userId: userId,
    now: DateTime.utc(2026, 11, 1),
  ).copyWith(isSynced: true);

  test('adopts CVs from the same email on the other project', () async {
    await repository.save(cv('a', 'primary-user'), markAsLocalChange: false);
    await repository.save(cv('guest', null), markAsLocalChange: false);
    await repository.save(
      cv('other', 'someone-else'),
      markAsLocalChange: false,
    );
    final adopter = LinkedAccountCvAdopter(repository);

    // First sign-in on the primary project records the account.
    expect(
      await adopter.adopt(userId: 'primary-user', email: 'Anh@Example.com'),
      0,
    );
    // Later sign-in with the same email on the secondary project.
    final adopted = await adopter.adopt(
      userId: 'secondary-user',
      email: 'anh@example.com',
    );

    expect(adopted, 1);
    final moved = await repository.getById('a');
    expect(moved?.userId, 'secondary-user');
    expect(moved?.isSynced, isFalse);
    expect(moved?.updatedAt, DateTime.utc(2026, 11, 1));
    expect((await repository.getById('guest'))?.userId, isNull);
    expect((await repository.getById('other'))?.userId, 'someone-else');
  });
}
