import 'package:cv_maker_mobile/features/cv_editor/domain/models/month_date.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repairs month dates saved with the Vietnam offset', () {
    // "11/2026" typed in UTC+7 used to be stored as 31 Oct 17:00 UTC.
    expect(parseMonthDate('2026-10-31T17:00:00.000Z'), DateTime.utc(2026, 11));
    expect(parseMonthDate('2026-12-31T17:00:00.000Z'), DateTime.utc(2027));
  });

  test('keeps correct dates and real timestamps unchanged', () {
    expect(parseMonthDate('2026-11-01T00:00:00.000Z'), DateTime.utc(2026, 11));
    // 17:00 in the middle of a month is a real time, not a shifted month.
    expect(
      parseMonthDate('2026-11-15T17:00:00.000Z'),
      DateTime.utc(2026, 11, 15, 17),
    );
  });

  test('projects read from storage show the intended month', () {
    final project = ProjectModel.fromJson({
      'id': 'p1',
      'name': 'AIFP',
      'role': 'Developer',
      'description': '',
      'technologies': <String>[],
      'startDate': '2026-10-31T17:00:00.000Z',
    });
    expect(project.startDate, DateTime.utc(2026, 11));
  });
}
