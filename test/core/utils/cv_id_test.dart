import 'package:cv_maker_mobile/core/utils/cv_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new CV ids are unique version 4 UUIDs', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = List.generate(200, (_) => newCvId());

    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(ids.length));
  });
}
