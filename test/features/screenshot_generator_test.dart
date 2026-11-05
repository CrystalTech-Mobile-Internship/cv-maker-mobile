import 'dart:io';
import 'dart:ui' as ui;

import 'package:cv_maker_mobile/app/theme.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cloud_sync_preview.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/education_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/experience_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/personal_info_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/project_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_completion_service.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/editor_typography_toolbar.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/experience_tab.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/section_reorder_sheet.dart';
import 'package:cv_maker_mobile/features/cv_management/presentation/widgets/cloud_sync_preview_sheet.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/export_pdf_dialog.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_interactive_section_reorder.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/template_gallery_sheet.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_preview_color_sheet.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/skill_bank_sheet.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/ats_action_verbs_sheet.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_page_fit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const screenshotDir = 'C:/Users/ADMIN/.gemini/antigravity/brain/e16381db-4d8d-426a-84e8-ecae1f4f5a63/screenshots';

Future<void> loadFonts() async {
  try {
    final regularData = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    final boldData = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();

    final robotoLoader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.view(regularData.buffer)))
      ..addFont(Future.value(ByteData.view(boldData.buffer)));
    await robotoLoader.load();

    final interLoader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.view(regularData.buffer)))
      ..addFont(Future.value(ByteData.view(boldData.buffer)));
    await interLoader.load();

    const iconPath = r'C:\Users\ADMIN\AppData\Local\FlutterSDK\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf';
    if (File(iconPath).existsSync()) {
      final iconData = File(iconPath).readAsBytesSync();
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(iconData.buffer)));
      await iconLoader.load();
    }
  } catch (e) {
    print('Font loading notice: $e');
  }
}

Future<void> saveScreenshot(WidgetTester tester, GlobalKey key, String filename) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    image.dispose();

    final dir = Directory(screenshotDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$filename').writeAsBytesSync(bytes);
    print('CAPTURED: $filename (${bytes.length} bytes)');
  });
}

final testTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    primary: const Color(0xFF4F46E5),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
);

CvModel getSampleCv() {
  final now = DateTime.utc(2026, 11, 4);
  return CvModel(
    id: 'sample-cv-1',
    title: 'CV Kỹ sư phần mềm Flutter',
    templateId: 'harvard_ats',
    primaryColor: '#1E293B',
    fontSizeScale: 1.0,
    summary:
        'Kỹ sư phần mềm Flutter với tư duy lập trình vững chắc, thành thạo Clean Architecture, Riverpod và cơ chế Offline-First SQLite. Đam mê xây dựng trải nghiệm mượt mà, tối ưu hiệu năng và code sạch.',
    personalInfo: const PersonalInfoModel(
      fullName: 'Nguyễn Tuấn Anh',
      targetRole: 'Mobile Software Engineer',
      email: 'tuananh@example.com',
      phone: '0901 234 567',
      address: 'Hà Nội, Việt Nam',
    ),
    educations: [
      EducationModel(
        id: 'edu-1',
        institution: 'Đại học Bách Khoa Hà Nội',
        degree: 'Kỹ sư',
        fieldOfStudy: 'Công nghệ Thông tin',
        startDate: DateTime.utc(2020, 9, 1),
        endDate: DateTime.utc(2024, 6, 1),
        isCurrent: false,
        gpa: '3.6 / 4.0',
      ),
    ],
    experiences: [
      ExperienceModel(
        id: 'exp-1',
        company: 'CrystalTech Corp',
        jobTitle: 'Flutter Developer Intern',
        location: 'Hà Nội',
        startDate: DateTime.utc(2024, 6, 1),
        isCurrent: true,
        bulletPoints: [
          'Phát triển ứng dụng Smart CV Maker Mobile sử dụng Flutter, Riverpod và SQLite/Drift.',
          'Triển khai xuất file PDF vector A4 và Word (.docx) chuẩn OpenXML chạy 100% offline.',
          'Tối ưu hóa giao diện đa nền tảng phản hồi dưới 16ms trên thiết bị thật Samsung Galaxy A11.',
        ],
      ),
    ],
    skills: const [
      SkillModel(id: 's-1', name: 'Flutter & Dart', category: SkillCategory.hard, proficiency: 90),
      SkillModel(id: 's-2', name: 'Clean Architecture & Riverpod', category: SkillCategory.hard, proficiency: 85),
      SkillModel(id: 's-3', name: 'SQLite & Supabase', category: SkillCategory.hard, proficiency: 80),
      SkillModel(id: 's-4', name: 'Giải quyết vấn đề & Làm việc nhóm', category: SkillCategory.soft, proficiency: 90),
    ],
    projects: [
      ProjectModel(
        id: 'p-1',
        name: 'Smart CV Maker Mobile',
        role: 'Lead Mobile Developer',
        technologies: ['Flutter', 'Riverpod', 'Drift SQLite', 'Supabase'],
        description: 'Ứng dụng tạo CV chuyên nghiệp với xem trước A4, xuất PDF/Word và sao lưu ngoại tuyến.',
        sourceUrl: 'https://github.com/CrystalTech-Mobile-Internship/cv-maker-mobile',
        startDate: DateTime.utc(2024, 8, 1),
      ),
    ],
    isSynced: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFonts();
  });

  testWidgets('01 Capture Editor Typography Toolbar & Score Badge', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    final summaryCtrl = TextEditingController(text: getSampleCv().summary);

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chỉnh sửa CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Đã tự động lưu trên máy (13:30)', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF15803D).withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text('88% Hoàn thiện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                  ],
                ),
              ),
              const IconButton(icon: Icon(Icons.swap_vert_rounded), onPressed: null),
              const IconButton(icon: Icon(Icons.picture_as_pdf_outlined), onPressed: null),
            ],
          ),
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditorTypographyToolbar(
                    currentScale: 1.15,
                    language: 'vi',
                    currentColor: '#1E293B',
                    onScaleChanged: (_) {},
                    onOpenSectionReorder: () {},
                    onOpenStarterSamples: () {},
                    textController: summaryCtrl,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandIndigo.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_outline, color: AppTheme.brandIndigo),
                              ),
                              const SizedBox(width: 10),
                              const Text('Thông tin cá nhân & Tóm tắt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Nguyễn Tuấn Anh • Mobile Software Engineer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('tuananh@example.com • 0901 234 567 • Hà Nội', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(getSampleCv().summary, style: const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_01_editor_typography.png');
  });

  testWidgets('02 Capture Contextual Starter Chips', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    final summaryCtrl = TextEditingController(text: getSampleCv().summary);

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tóm tắt bản thân (Summary)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {},
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Tối ưu AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: summaryCtrl,
                    minLines: 4,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Gợi ý mẫu nhanh ("Điền vào mẫu"):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.flash_on_rounded, size: 15, color: AppTheme.brandIndigo),
                        label: const Text('Mobile / Flutter Dev', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {},
                        backgroundColor: AppTheme.indigoSurface,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.school_outlined, size: 15, color: AppTheme.accentTeal),
                        label: const Text('Sinh viên IT / Fresher', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {},
                        backgroundColor: AppTheme.tealSurface,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.cloud_queue_rounded, size: 15, color: Colors.blue),
                        label: const Text('Lập trình Backend', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {},
                        backgroundColor: Colors.blue.shade50,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.trending_up_rounded, size: 15, color: Colors.orange),
                        label: const Text('Kinh doanh & Marketing', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () {},
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_02_inline_starter_chips.png');
  });

  testWidgets('03 Capture Empty State Fill-in Buttons', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Kinh nghiệm làm việc')),
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.white,
              child: ExperienceTab(
                experiences: const [],
                onAddExperience: () {},
                onUseStarterExperience: () {},
                language: 'vi',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_03_empty_state_starters.png');
  });

  testWidgets('04 Capture Section Reorder Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SectionReorderSheet(
                  initialOrder: const ['summary', 'experience', 'projects', 'skills', 'education', 'certifications'],
                  language: 'vi',
                  onOrderChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_04_section_reorder_sheet.png');
  });

  testWidgets('05 Capture Cloud Sync Preview Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    const preview = CloudSyncPreview(
      targetBackend: 'Supabase Primary',
      userEmail: 'tuananh@example.com',
      pendingUploadCount: 3,
      pendingDownloadCount: 1,
      conflictCount: 1,
      pendingDeletionCount: 0,
      localCvCount: 4,
      remoteCvCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: CloudSyncPreviewSheet(
                preview: preview,
                onConfirmSync: () {},
                onExportBackup: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_05_cloud_sync_preview.png');
  });

  testWidgets('06 Capture Export Format Selector Dialog', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: ExportPdfDialog(
                initialFileName: 'CV_Nguyen_Tuan_Anh_Flutter',
                isEnglish: false,
                onConfirm: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_06_export_format_dialog.png');
  });

  testWidgets('07 Capture Completeness Checklist Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    final cv = getSampleCv();
    final report = CvCompletionService.evaluate(cv);

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.brandIndigo.withAlpha(25),
                          foregroundColor: AppTheme.primarySlate,
                          child: const Icon(Icons.fact_check_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Checklist hoàn thiện CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text('${report.completedCount}/${report.items.length} mục hoàn thành • ${report.percentage}%',
                                  style: const TextStyle(color: AppTheme.mutedText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: report.percentage / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...report.items.map(
                      (item) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: item.isCompleted ? const Color(0xFF15803D) : AppTheme.mutedText,
                        ),
                        title: Text(item.label, style: TextStyle(fontWeight: item.isCompleted ? FontWeight.w500 : FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_07_completeness_checklist.png');
  });

  testWidgets('08 Capture Color Palette Theme Dialog', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    Color parseHex(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF1E293B);
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.brandIndigo.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.palette_outlined, color: AppTheme.brandIndigo, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Bảng màu chủ đạo CV',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 360,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: EditorTypographyToolbar.colorPresets.map((preset) {
                      final hex = preset['hex']!;
                      final color = parseHex(hex);
                      final isSelected = hex == '#1E293B';
                      final name = preset['nameVi']!;

                      return Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withAlpha(25) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? color : Colors.grey.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_08_color_palette_dialog.png');
  });

  testWidgets('09 Capture Preview Screen with Segmented Mode & ATS Badge', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    final cv = getSampleCv();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Xem trước CV'),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF15803D).withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text('100% ATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                  ],
                ),
              ),
              IconButton(
                icon: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const Icon(Icons.palette_outlined),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.style_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    color: Colors.white,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            icon: Icon(Icons.picture_as_pdf_outlined, size: 16),
                            label: Text('Trang A4 (PDF)'),
                          ),
                          ButtonSegment(
                            value: 1,
                            icon: Icon(Icons.drag_indicator_rounded, size: 16),
                            label: Text('Bố cục kéo thả'),
                          ),
                        ],
                        selected: const {0},
                        onSelectionChanged: (_) {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              cv.personalInfo.fullName.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              cv.personalInfo.targetRole.toUpperCase(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('MỤC TIÊU NGHỀ NGHIỆP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text(cv.summary, style: const TextStyle(fontSize: 11, height: 1.4)),
                          const SizedBox(height: 14),
                          const Text('KINH NGHIỆM LÀM VIỆC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('${cv.experiences.first.jobTitle} • ${cv.experiences.first.company}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_09_preview_segmented_mode.png');
  });

  testWidgets('10 Capture Preview Screen Interactive Drag and Drop Mode', (tester) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    final cv = getSampleCv();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Xem trước CV'),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF15803D).withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text('100% ATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.palette_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.style_outlined), onPressed: () {}),
            ],
          ),
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    color: Colors.white,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            icon: Icon(Icons.picture_as_pdf_outlined, size: 16),
                            label: Text('Trang A4 (PDF)'),
                          ),
                          ButtonSegment(
                            value: 1,
                            icon: Icon(Icons.drag_indicator_rounded, size: 16),
                            label: Text('Bố cục kéo thả'),
                          ),
                        ],
                        selected: const {1},
                        onSelectionChanged: (_) {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: CvInteractiveSectionReorder(
                      cv: cv,
                      language: 'vi',
                      onOrderChanged: (_) {},
                      onResetToDefault: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_10_preview_interactive_drag_drop.png');
  });

  testWidgets('11 Capture Template Gallery Picker Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 520),
                child: TemplateGallerySheet(
                  selectedTemplateId: 'harvard_ats',
                  isEnglish: false,
                  onSelectTemplate: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_11_preview_template_gallery.png');
  });

  testWidgets('12 Capture Preview Color Theme Palette Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 950);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: CvPreviewColorSheet(
                currentColor: '#1E293B',
                isEnglish: false,
                onColorSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_12_preview_color_theme_sheet.png');
  });

  testWidgets('13 Capture Skill Bank Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: SkillBankSheet(
                existingSkills: const [
                  SkillModel(id: 's1', name: 'Flutter & Dart', category: SkillCategory.hard),
                  SkillModel(id: 's2', name: 'SQLite / Drift Database', category: SkillCategory.hard),
                ],
                onAddSkill: (_) {},
                language: 'vi',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_13_skill_bank_sheet.png');
  });

  testWidgets('14 Capture ATS Action Verbs & Formula Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1150);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: AtsActionVerbsSheet(
                language: 'vi',
                onInsertVerb: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_14_ats_action_verbs_sheet.png');
  });

  testWidgets('15 Capture Preview Page Fit & Layout Optimizer Sheet', (tester) async {
    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.bottomCenter,
              child: CvPageFitSheet(
                currentScale: 0.85,
                isEnglish: false,
                onScaleChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await saveScreenshot(tester, key, 'screenshot_15_preview_page_fit_sheet.png');
  });
}
