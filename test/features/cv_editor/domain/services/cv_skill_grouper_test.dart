import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_skill_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

SkillModel hard(String name, {String group = ''}) => SkillModel(
  id: name,
  name: name,
  category: SkillCategory.hard,
  group: group,
);

void main() {
  test('groups common technologies into readable lines', () {
    final lines = CvSkillGrouper.lines([
      hard('Java'),
      hard('Spring Boot'),
      hard('ReactJS'),
      hard('HTML/CSS'),
      hard('React Native'),
      hard('PostgreSQL'),
      hard('AWS S3'),
      hard('Git/GitHub'),
      hard('Figma'),
      hard('Blockchain'),
      const SkillModel(id: 's', name: 'Teamwork', category: SkillCategory.soft),
    ], isEn: false);

    expect(lines.map((l) => '${l.label}: ${l.text}'), [
      'Ngôn ngữ: Java',
      'Frontend: ReactJS, HTML/CSS',
      'Backend: Spring Boot',
      'Mobile: React Native',
      'Cơ sở dữ liệu: PostgreSQL',
      'DevOps & Cloud: AWS S3',
      'Công cụ: Git/GitHub, Figma',
      'Khác: Blockchain',
      'Kỹ năng mềm: Teamwork',
    ]);
  });

  test('a typed group wins and matches known groups case-insensitively', () {
    final lines = CvSkillGrouper.lines([
      hard('Redis', group: 'backend'),
      hard('NestJS'),
      hard('Unity', group: 'Game'),
    ], isEn: false);

    expect(lines.map((l) => '${l.label}: ${l.text}'), [
      'Backend: Redis, NestJS',
      'Game: Unity',
    ]);
  });

  test('keeps the single classic line when nothing is recognised', () {
    final lines = CvSkillGrouper.lines([
      hard('Kế toán thuế'),
      hard('Lập báo cáo'),
    ], isEn: false);

    expect(lines.single.label, 'Kỹ năng chuyên môn');
    expect(lines.single.text, 'Kế toán thuế, Lập báo cáo');
  });

  test('group survives JSON round trip and stays out when empty', () {
    final skill = hard('Docker', group: 'DevOps & Cloud');
    expect(SkillModel.fromJson(skill.toJson()).group, 'DevOps & Cloud');
    expect(hard('Docker').toJson().containsKey('group'), isFalse);
  });
}
