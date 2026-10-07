import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/cv_model.dart';
import '../../domain/models/education_model.dart';
import '../../domain/models/experience_model.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/skill_model.dart';

class CvRemoteDataSourceException implements Exception {
  const CvRemoteDataSourceException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'CvRemoteDataSourceException: $message';
}

/// Supabase data source for CVs owned by the currently authenticated user.
///
/// Widgets should call this class through a repository/controller. They should
/// not know table names or contain Supabase queries directly.
class CvRemoteDataSource {
  CvRemoteDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseService.requiredClient;

  final SupabaseClient _client;

  Future<List<CvModel>> fetchUserCvs() async {
    final userId = _requireUserId();

    try {
      final rows = await _client
          .from('cvs')
          .select('*, cv_sections(*, cv_items(*))')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (rows as List)
          .whereType<Map>()
          .map((row) => _mapCvRow(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw CvRemoteDataSourceException(
        'Không thể tải CV từ database: ${error.message}',
        cause: error,
      );
    } on AuthException catch (error) {
      throw CvRemoteDataSourceException(
        'Phiên đăng nhập không hợp lệ: ${error.message}',
        cause: error,
      );
    } catch (error) {
      throw CvRemoteDataSourceException(
        'Không thể kết nối Supabase. Hãy kiểm tra mạng và cấu hình .env.',
        cause: error,
      );
    }
  }

  Future<CvModel> upsertCv(CvModel cv) async {
    final userId = _requireUserId();

    try {
      final row = await _client
          .from('cvs')
          .upsert(cv.toMap(ownerId: userId))
          .select()
          .single();
      final savedCvId = row['id'] as String;

      // Sections are replaced as one logical snapshot. The foreign key cascade
      // removes their old items before the new snapshot is inserted.
      await _client.from('cv_sections').delete().eq('cv_id', savedCvId);
      await _upsertSections(savedCvId, cv);

      return cv.copyWith(id: savedCvId, userId: userId);
    } on PostgrestException catch (error) {
      throw CvRemoteDataSourceException(
        'Không thể lưu CV vào database: ${error.message}',
        cause: error,
      );
    } on AuthException catch (error) {
      throw CvRemoteDataSourceException(
        'Phiên đăng nhập không hợp lệ: ${error.message}',
        cause: error,
      );
    } catch (error) {
      if (error is CvRemoteDataSourceException) rethrow;
      throw CvRemoteDataSourceException(
        'Không thể đồng bộ CV. Hãy kiểm tra mạng và quyền truy cập.',
        cause: error,
      );
    }
  }

  Future<void> deleteRemoteCv(String cvId) async {
    final userId = _requireUserId();

    try {
      await _client.from('cvs').delete().eq('id', cvId).eq('user_id', userId);
    } on PostgrestException catch (error) {
      throw CvRemoteDataSourceException(
        'Không thể xoá CV từ database: ${error.message}',
        cause: error,
      );
    } catch (error) {
      throw CvRemoteDataSourceException(
        'Không thể xoá CV. Hãy kiểm tra mạng và quyền truy cập.',
        cause: error,
      );
    }
  }

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const CvRemoteDataSourceException(
        'Cần đăng nhập trước khi đọc hoặc ghi CV.',
      );
    }
    return user.id;
  }

  CvModel _mapCvRow(Map<String, dynamic> row) {
    final sections =
        (row['cv_sections'] as List?)
            ?.whereType<Map>()
            .map((section) => Map<String, dynamic>.from(section))
            .toList() ??
        const <Map<String, dynamic>>[];
    final base = CvModel.fromMap(row);

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final section in sections) {
      final type = section['section_type'] as String?;
      if (type == null) continue;
      final items =
          (section['cv_items'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item['payload'] as Map))
              .toList() ??
          const <Map<String, dynamic>>[];
      grouped[type] = items;
    }

    return CvModel(
      id: base.id,
      userId: base.userId,
      title: base.title,
      templateId: base.templateId,
      primaryColor: base.primaryColor,
      fontSizeScale: base.fontSizeScale,
      summary: base.summary,
      personalInfo: base.personalInfo,
      educations:
          grouped['education']
              ?.map(EducationModel.fromMap)
              .toList(growable: false) ??
          const [],
      experiences:
          grouped['experience']
              ?.map(ExperienceModel.fromMap)
              .toList(growable: false) ??
          const [],
      skills:
          grouped['skills']?.map(SkillModel.fromMap).toList(growable: false) ??
          const [],
      projects:
          grouped['projects']
              ?.map(ProjectModel.fromMap)
              .toList(growable: false) ??
          const [],
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
    );
  }

  Future<void> _upsertSections(String cvId, CvModel cv) async {
    final sections =
        <({String type, String title, List<Map<String, dynamic>> items})>[
          (
            type: 'education',
            title: 'Học vấn',
            items: cv.educations
                .whereType<EducationModel>()
                .map((item) => item.toMap())
                .toList(),
          ),
          (
            type: 'experience',
            title: 'Kinh nghiệm',
            items: cv.experiences
                .whereType<ExperienceModel>()
                .map((item) => item.toMap())
                .toList(),
          ),
          (
            type: 'skills',
            title: 'Kỹ năng',
            items: cv.skills
                .whereType<SkillModel>()
                .map((item) => item.toMap())
                .toList(),
          ),
          (
            type: 'projects',
            title: 'Dự án',
            items: cv.projects
                .whereType<ProjectModel>()
                .map((item) => item.toMap())
                .toList(),
          ),
        ];

    for (var index = 0; index < sections.length; index++) {
      final definition = sections[index];
      final section = await _client
          .from('cv_sections')
          .insert({
            'cv_id': cvId,
            'section_type': definition.type,
            'title': definition.title,
            'order_index': index,
          })
          .select('id')
          .single();

      final sectionId = section['id'] as String;
      if (definition.items.isEmpty) continue;

      await _client.from('cv_items').insert([
        for (
          var itemIndex = 0;
          itemIndex < definition.items.length;
          itemIndex++
        )
          {
            'cv_id': cvId,
            'section_id': sectionId,
            'item_type': definition.type,
            'payload': definition.items[itemIndex],
            'order_index': itemIndex,
          },
      ]);
    }
  }
}
