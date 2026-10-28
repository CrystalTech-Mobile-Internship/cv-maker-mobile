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
    required this.isAiLoading,
    required this.avatarPath,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
    required this.supportsProfilePhoto,
    required this.avatarPosition,
    required this.onAvatarPositionChanged,
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
  final bool isAiLoading;
  final String? avatarPath;
  final Future<void> Function() onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final bool supportsProfilePhoto;
  final String avatarPosition;
  final ValueChanged<String> onAvatarPositionChanged;
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _ProfilePhotoPicker(
                language: language,
                avatarPath: avatarPath,
                supportsProfilePhoto: supportsProfilePhoto,
                onPickAvatar: onPickAvatar,
                onRemoveAvatar: onRemoveAvatar,
                avatarPosition: avatarPosition,
                onAvatarPositionChanged: onAvatarPositionChanged,
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
                key: const Key('target-role-field'),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final emailField = TextField(
                    key: const Key('email-field'),
                    controller: emailController,
                    onChanged: onFieldChanged,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  );
                  final phoneField = TextField(
                    key: const Key('phone-field'),
                    controller: phoneController,
                    onChanged: onFieldChanged,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Phone Number *' : 'Số điện thoại *',
                      hintText: '0901 234 567',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  );

                  if (constraints.maxWidth < 520) {
                    return Column(
                      children: [
                        emailField,
                        const SizedBox(height: 14),
                        phoneField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: emailField),
                      const SizedBox(width: 12),
                      Expanded(child: phoneField),
                    ],
                  );
                },
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('polish-summary-with-ai'),
                    onPressed: isAiLoading ? null : onAiOptimize,
                    icon: isAiLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      isAiLoading
                          ? (_isEn ? 'Optimizing...' : 'Đang tối ưu...')
                          : (_isEn ? 'AI Optimize' : 'Tối ưu AI'),
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
                key: const Key('summary-field'),
                controller: summaryController,
                onChanged: onFieldChanged,
                minLines: 5,
                maxLines: 7,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
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
    required this.avatarPosition,
    required this.onAvatarPositionChanged,
  });

  final String language;
  final String? avatarPath;
  final bool supportsProfilePhoto;
  final Future<void> Function() onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final String avatarPosition;
  final ValueChanged<String> onAvatarPositionChanged;

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
                    isEn
                        ? 'Profile photo (optional)'
                        : 'Ảnh đại diện (tuỳ chọn)',
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
                              : 'Hỗ trợ Minimalist Clean, Creative Tech và Professional Sidebar.'),
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
                  if (hasImage) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'left',
                          label: Text(isEn ? 'Left' : 'Trái'),
                        ),
                        ButtonSegment(
                          value: 'right',
                          label: Text(isEn ? 'Right' : 'Phải'),
                        ),
                      ],
                      selected: {avatarPosition},
                      onSelectionChanged: (value) =>
                          onAvatarPositionChanged(value.first),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
