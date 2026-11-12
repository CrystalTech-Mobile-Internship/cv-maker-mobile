class ActionVerbItem {
  const ActionVerbItem({
    required this.verbVi,
    required this.verbEn,
    required this.category,
    required this.contextVi,
    required this.contextEn,
    required this.exampleVi,
    required this.exampleEn,
  });

  final String verbVi;
  final String verbEn;
  final String
  category; // 'engineering', 'optimization', 'leadership', 'analysis'
  final String contextVi;
  final String contextEn;
  final String exampleVi;
  final String exampleEn;

  String verb(String language) => language == 'en' ? verbEn : verbVi;
  String context(String language) => language == 'en' ? contextEn : contextVi;
  String example(String language) => language == 'en' ? exampleEn : exampleVi;
}

abstract final class CvActionVerbsService {
  static const List<ActionVerbItem> verbs = [
    // Engineering & Build
    ActionVerbItem(
      verbVi: 'Phát triển',
      verbEn: 'Developed',
      category: 'engineering',
      contextVi: 'Xây dựng tính năng, mô-đun hoặc toàn bộ sản phẩm',
      contextEn: 'Building new features, modules, or complete applications',
      exampleVi:
          'Phát triển mô-đun xác thực OAuth2 và mã hóa dữ liệu cục bộ với SQLite cho hơn 10.000 người dùng.',
      exampleEn:
          'Developed OAuth2 authentication module and local SQLite encryption for 10,000+ active users.',
    ),
    ActionVerbItem(
      verbVi: 'Thiết kế kiến trúc',
      verbEn: 'Architected',
      category: 'engineering',
      contextVi:
          'Định hình cấu trúc hệ thống, phân chia tầng Clean Architecture',
      contextEn:
          'Designing scalable multi-layer system architecture and boundaries',
      exampleVi:
          'Thiết kế kiến trúc Clean Architecture 3 tầng tách biệt Domain, Data và Presentation giúp tăng 30% tốc độ phát triển tính năng.',
      exampleEn:
          'Architected a 3-layer Clean Architecture system decoupling Domain, Data, and Presentation layers, boosting team velocity by 30%.',
    ),
    ActionVerbItem(
      verbVi: 'Triển khai',
      verbEn: 'Implemented',
      category: 'engineering',
      contextVi: 'Hiện thực hóa giải pháp kỹ thuật, API hoặc thuật toán',
      contextEn:
          'Putting technical solutions, algorithms, or API endpoints into production',
      exampleVi:
          'Triển khai luồng đồng bộ đa nền tảng với cơ chế Last-Write-Wins chống xung đột dữ liệu offline.',
      exampleEn:
          'Implemented cross-platform offline synchronization using Last-Write-Wins conflict resolution.',
    ),
    ActionVerbItem(
      verbVi: 'Tích hợp',
      verbEn: 'Integrated',
      category: 'engineering',
      contextVi: 'Kết nối dịch vụ bên thứ ba (Cổng thanh toán, Cloud, AI)',
      contextEn:
          'Connecting third-party SDKs, Cloud APIs, Payment gateways or AI engines',
      exampleVi:
          'Tích hợp Supabase Backend và Gemini API hỗ trợ tóm tắt CV thông minh với độ trễ dưới 800ms.',
      exampleEn:
          'Integrated Supabase backend and Gemini API for smart CV summarization with sub-800ms response times.',
    ),

    // Optimization & Improvement
    ActionVerbItem(
      verbVi: 'Tối ưu hóa',
      verbEn: 'Optimized',
      category: 'optimization',
      contextVi: 'Cải thiện tốc độ, kích thước tệp, tài nguyên CPU/RAM',
      contextEn:
          'Improving runtime speed, file size, memory footprint, or battery usage',
      exampleVi:
          'Tối ưu hóa thuật toán render danh sách với pagination và lazy loading, giảm 50% mức tiêu thụ RAM.',
      exampleEn:
          'Optimized list rendering with pagination and lazy loading, cutting memory consumption by 50%.',
    ),
    ActionVerbItem(
      verbVi: 'Tinh gọn',
      verbEn: 'Streamlined',
      category: 'optimization',
      contextVi: 'Rút ngắn quy trình, giảm bớt thao tác phức tạp',
      contextEn:
          'Eliminating redundant workflows and simplifying complex user operations',
      exampleVi:
          'Tinh gọn quy trình tạo hồ sơ từ 7 bước xuống 3 bước, tăng 25% tỷ lệ hoàn thiện hồ sơ của ứng viên.',
      exampleEn:
          'Streamlined candidate onboarding from 7 steps to 3 steps, boosting completion rate by 25%.',
    ),
    ActionVerbItem(
      verbVi: 'Tái cấu trúc',
      verbEn: 'Refactored',
      category: 'optimization',
      contextVi: 'Dọn dẹp code, nâng cao độ bền vững và khả năng kiểm thử',
      contextEn:
          'Cleaning legacy code, improving maintainability and testability',
      exampleVi:
          'Tái cấu trúc toàn bộ module thanh toán sang Riverpod StateNotifier, nâng độ bao phủ test từ 45% lên 88%.',
      exampleEn:
          'Refactored legacy payment module to Riverpod StateNotifier, elevating test coverage from 45% to 88%.',
    ),

    // Leadership & Coordination
    ActionVerbItem(
      verbVi: 'Dẫn dắt',
      verbEn: 'Spearheaded',
      category: 'leadership',
      contextVi: 'Tiên phong khởi xướng dự án hoặc công nghệ mới',
      contextEn: 'Leading an initiative or adopting critical new technologies',
      exampleVi:
          'Dẫn dắt dự án chuyển đổi ứng dụng sang Flutter 3.x, bàn giao đúng hạn trước tiến độ 2 tuần.',
      exampleEn:
          'Spearheaded the migration to Flutter 3.x, delivering production releases 2 weeks ahead of schedule.',
    ),
    ActionVerbItem(
      verbVi: 'Điều phối & Hướng dẫn',
      verbEn: 'Mentored',
      category: 'leadership',
      contextVi:
          'Hỗ trợ các thành viên junior, review code và chia sẻ kiến thức',
      contextEn:
          'Guiding junior engineers, conducting code reviews, and technical onboarding',
      exampleVi:
          'Hướng dẫn 3 kỹ sư thực tập về Clean Architecture và Git flow, giúp nhóm đạt 100% KPI quý.',
      exampleEn:
          'Mentored 3 intern engineers in Clean Architecture and Git workflow, leading to 100% quarterly KPI achievement.',
    ),

    // Analysis & Research
    ActionVerbItem(
      verbVi: 'Phân tích & Đánh giá',
      verbEn: 'Analyzed',
      category: 'analysis',
      contextVi: 'Khảo sát số liệu, phát hiện điểm nghẽn và đưa ra phương án',
      contextEn:
          'Examining data, diagnosing bottlenecks, and proposing evidence-based solutions',
      exampleVi:
          'Phân tích crash logs bằng Firebase Crashlytics, xử lý triệt để 12 lỗi crash tiềm ẩn trên thiết bị Android cũ.',
      exampleEn:
          'Analyzed production crash logs with Firebase Crashlytics, resolving 12 critical crashes on legacy Android devices.',
    ),
    ActionVerbItem(
      verbVi: 'Đo lường & Kiểm định',
      verbEn: 'Benchmarked',
      category: 'analysis',
      contextVi: 'So sánh hiệu năng giữa các giải pháp công nghệ',
      contextEn:
          'Comparing performance metrics between technical frameworks or solutions',
      exampleVi:
          'Đo lường và đánh giá hiệu năng giữa SQLite và Hive, chọn SQLite Drift đảm bảo tính toàn vẹn ACID.',
      exampleEn:
          'Benchmarked performance between SQLite and Hive, selecting SQLite Drift to ensure strict ACID compliance.',
    ),
  ];

  static List<ActionVerbItem> getByCategory(String category) {
    if (category == 'all') return verbs;
    return verbs.where((item) => item.category == category).toList();
  }
}
