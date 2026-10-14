import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Form tab for editing personal information and career summary.
class PersonalInfoTab extends StatelessWidget {
  const PersonalInfoTab({
    super.key,
    required this.titleController,
    required this.fullNameController,
    required this.roleController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
    required this.summaryController,
    required this.onFieldChanged,
    required this.onAiOptimize,
    required this.avatarPath,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
    required this.supportsProfilePhoto,
    this.language = 'vi',
  });

  final TextEditingController titleController;
  final TextEditingController fullNameController;
  final TextEditingController roleController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController summaryController;
  final ValueChanged<String>? onFieldChanged;
  final VoidCallback onAiOptimize;
  final String? avatarPath;
  final Future<void> Function() onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final bool supportsProfilePhoto;
  final String language;

  bool get _isEn => language == 'en';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                onChanged: onFieldChanged,
                decoration: InputDecoration(
                  labelText: _isEn ? 'CV Title' : 'Tên CV',
                  hintText: _isEn
                      ? 'e.g. Flutter Software Engineer Resume'
                      : 'VD: CV Flutter Software Engineer',
                  prefixIcon: const Icon(Icons.title_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEn ? 'Basic Information' : 'Thông tin cơ bản',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              _ProfilePhotoPicker(
                language: language,
                avatarPath: avatarPath,
                supportsProfilePhoto: supportsProfilePhoto,
                onPickAvatar: onPickAvatar,
                onRemoveAvatar: onRemoveAvatar,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: fullNameController,
                onChanged: onFieldChanged,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Full Name *' : 'Họ và tên *',
                  hintText: _isEn ? 'Nguyen Tuan Anh' : 'Nguyễn Tuấn Anh',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roleController,
                onChanged: onFieldChanged,
                decoration: InputDecoration(
                  labelText: _isEn
                      ? 'Target Role / Job Title *'
                      : 'Vị trí ứng tuyển mục tiêu *',
                  hintText: _isEn
                      ? 'Flutter Software Engineer'
                      : 'Kỹ sư phần mềm Flutter',
                  prefixIcon: const Icon(Icons.work_history_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      onChanged: onFieldChanged,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Email *' : 'Email *',
                        hintText: 'user@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      onChanged: onFieldChanged,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Phone Number *' : 'Số điện thoại *',
                        hintText: '0901 234 567',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: locationController,
                onChanged: onFieldChanged,
                decoration: InputDecoration(
                  labelText: _isEn
                      ? 'Location / City, Country'
                      : 'Địa chỉ / Thành phố',
                  hintText: _isEn ? 'Hanoi, Vietnam' : 'Hà Nội, Việt Nam',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Summary header with AI button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isEn
                          ? 'Professional Summary'
                          : 'Tóm tắt bản thân (Summary)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onAiOptimize,
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.accentTeal,
                    ),
                    label: Text(
                      _isEn ? 'AI Optimize' : 'Tối ưu AI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: summaryController,
                onChanged: onFieldChanged,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isEn
                      ? 'Write 2-3 concise sentences highlighting core technical strengths, measurable achievements, and career focus...'
                      : 'Viết 2-3 câu ngắn gọn mô tả năng lực cốt lõi, thành tựu nổi bật và định hướng nghề nghiệp...',
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.language,
    required this.avatarPath,
    required this.supportsProfilePhoto,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
  });

  final String language;
  final String? avatarPath;
  final bool supportsProfilePhoto;
  final Future<void> Function() onPickAvatar;
  final VoidCallback onRemoveAvatar;

  @override
  Widget build(BuildContext context) {
    final isEn = language == 'en';
    final file = avatarPath == null ? null : File(avatarPath!);
    final hasImage = file?.existsSync() ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: supportsProfilePhoto
            ? AppTheme.accentTeal.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        border: Border.all(
          color: supportsProfilePhoto
              ? AppTheme.accentTeal.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              foregroundImage: hasImage ? FileImage(file!) : null,
              child: hasImage
                  ? null
                  : const Icon(Icons.person_rounded, size: 38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Profile photo (optional)' : 'Ảnh đại diện (tuỳ chọn)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    supportsProfilePhoto
                        ? (isEn
                              ? 'Shown in Minimalist Clean and Creative Tech.'
                              : 'Hiển thị trên Minimalist Clean và Creative Tech.')
                        : (isEn
                              ? 'Choose a photo template in Preview to display it.'
                              : 'Chọn mẫu có ảnh ở màn hình Xem trước để hiển thị.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FilledButton.tonalIcon(
                        key: const Key('pick-profile-photo'),
                        onPressed: onPickAvatar,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          hasImage
                              ? (isEn ? 'Change photo' : 'Đổi ảnh')
                              : (isEn ? 'Add photo' : 'Thêm ảnh'),
                        ),
                      ),
                      if (hasImage)
                        TextButton.icon(
                          key: const Key('remove-profile-photo'),
                          onPressed: onRemoveAvatar,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(isEn ? 'Remove' : 'Xoá'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
