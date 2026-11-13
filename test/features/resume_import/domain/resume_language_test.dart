import 'package:cv_maker_mobile/features/resume_import/domain/services/resume_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English CVs stay English even with a Vietnamese name', () {
    expect(
      detectResumeLanguage(
        'NGUYỄN VĂN A\nFinal-year Software Engineering student focused on '
        'backend development and building reliable web applications.',
      ),
      'en',
    );
  });

  test('Vietnamese CVs are recognised', () {
    expect(
      detectResumeLanguage(
        'Sinh viên năm cuối ngành Kỹ thuật phần mềm, có kinh nghiệm xây dựng '
        'ứng dụng di động và mong muốn ứng tuyển vị trí thực tập sinh.',
      ),
      'vi',
    );
  });
}
