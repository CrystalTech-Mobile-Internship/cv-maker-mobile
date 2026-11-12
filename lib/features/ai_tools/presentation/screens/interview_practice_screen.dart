import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_management/presentation/controllers/cv_list_provider.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/interview_practice_controller.dart';
import '../widgets/ai_access_guard.dart';

/// Arguments when opened from a screen that already knows the CV/JD.
class InterviewPracticeArgs {
  const InterviewPracticeArgs({this.cvId, this.jobDescription = ''});

  final String? cvId;
  final String jobDescription;
}

class InterviewPracticeScreen extends ConsumerStatefulWidget {
  const InterviewPracticeScreen({super.key, this.args});

  final InterviewPracticeArgs? args;

  @override
  ConsumerState<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState
    extends ConsumerState<InterviewPracticeScreen> {
  late final _jd = TextEditingController(
    text: widget.args?.jobDescription ?? '',
  );
  final _answer = TextEditingController();
  String? _cvId;

  @override
  void initState() {
    super.initState();
    _cvId = widget.args?.cvId;
  }

  @override
  void dispose() {
    _jd.dispose();
    _answer.dispose();
    super.dispose();
  }

  CvModel? _selected(List<CvModel> cvs) {
    if (cvs.isEmpty) return null;
    return cvs.firstWhere((cv) => cv.id == _cvId, orElse: () => cvs.first);
  }

  Future<void> _start(CvModel cv) async {
    if (!await ensureAiAccess(
      context,
      ref,
      redirectPath: '/interview-practice',
    )) {
      return;
    }
    _answer.clear();
    await ref
        .read(interviewPracticeControllerProvider.notifier)
        .start(cv, jobDescription: _jd.text);
  }

  void _goTo(int index) {
    final controller = ref.read(interviewPracticeControllerProvider.notifier);
    controller.goTo(index);
    final state = ref.read(interviewPracticeControllerProvider);
    _answer.text = state.answers[state.index] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cvs = ref.watch(cvListStreamProvider).valueOrNull ?? const [];
    final cv = _selected(cvs);
    final state = ref.watch(interviewPracticeControllerProvider);
    final controller = ref.read(interviewPracticeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Luyện phỏng vấn'),
        actions: const [AiQuotaChip(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (!state.hasQuestions) ...[
              const _Intro(),
              const SizedBox(height: 16),
              if (cvs.isEmpty)
                const Text(
                  'Bạn chưa có CV trên máy. Hãy tạo hoặc nhập CV trước.',
                  style: TextStyle(color: AppTheme.mutedText),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: cv?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'CV dùng để luyện',
                  ),
                  items: [
                    for (final item in cvs)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _cvId = value),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _jd,
                minLines: 3,
                maxLines: 6,
                maxLength: 6000,
                decoration: const InputDecoration(
                  labelText: 'Tin tuyển dụng (không bắt buộc)',
                  hintText: 'Dán tin tuyển dụng để câu hỏi sát với vị trí ứng tuyển hơn',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('practice-start'),
                onPressed: cv == null || state.isBusy ? null : () => _start(cv),
                child: Text(
                  state.isLoadingQuestions
                      ? 'AI đang soạn câu hỏi...'
                      : 'Bắt đầu (${AiCreditCost.interviewQuestions} lượt)',
                ),
              ),
            ] else ...[
              _QuestionStepper(
                total: state.questions.length,
                index: state.index,
                answered: state.feedback.keys.toSet(),
                onTap: _goTo,
              ),
              const SizedBox(height: 12),
              _QuestionCard(question: state.current!, number: state.index + 1),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('practice-answer'),
                controller: _answer,
                minLines: 4,
                maxLines: 10,
                maxLength: 3000,
                onChanged: controller.updateAnswer,
                decoration: const InputDecoration(
                  labelText: 'Câu trả lời của bạn',
                  hintText:
                      'Gợi ý: kể theo trình tự Tình huống → Việc cần làm → Hành động → Kết quả',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: state.index == 0 || state.isBusy
                        ? null
                        : () => _goTo(state.index - 1),
                    child: const Text('Câu trước'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('practice-evaluate'),
                      onPressed: state.isBusy || cv == null
                          ? null
                          : () => controller.evaluate(cv),
                      child: Text(
                        state.isEvaluating
                            ? 'Đang chấm...'
                            : 'Nhận xét (${AiCreditCost.answerFeedback} lượt)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed:
                        state.index >= state.questions.length - 1 ||
                            state.isBusy
                        ? null
                        : () => _goTo(state.index + 1),
                    child: const Text('Câu sau'),
                  ),
                ],
              ),
              if (state.feedback[state.index] != null) ...[
                const SizedBox(height: 12),
                _FeedbackCard(feedback: state.feedback[state.index]!),
              ],
              if (state.averageScore != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Điểm trung bình: ${state.averageScore!.toStringAsFixed(1)}/10 '
                  '(${state.feedback.length}/${state.questions.length} câu)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.isBusy || cv == null ? null : () => _start(cv),
                child: const Text('Tạo bộ câu hỏi mới'),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: state.errorCode == AiWritingFailureCode.quotaExceeded
                      ? AppTheme.amberSurface
                      : AppTheme.dangerRose.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(state.errorMessage!)),
                    if (state.errorCode == AiWritingFailureCode.quotaExceeded)
                      TextButton(
                        onPressed: () => context.push('/upgrade-pro'),
                        child: const Text('Nâng cấp'),
                      ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: controller.dismissError,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: const Text(
        'AI đọc CV của bạn (và tin tuyển dụng nếu có) để đặt 6 câu hỏi phỏng vấn sát thực tế. '
        'Trả lời từng câu, AI sẽ chấm điểm, chỉ ra điểm mạnh, điểm cần cải thiện '
        'và gợi ý câu trả lời mẫu dựa trên chính kinh nghiệm của bạn.',
        style: TextStyle(height: 1.45, color: AppTheme.primarySlate),
      ),
    );
  }
}

class _QuestionStepper extends StatelessWidget {
  const _QuestionStepper({
    required this.total,
    required this.index,
    required this.answered,
    required this.onTap,
  });

  final int total;
  final int index;
  final Set<int> answered;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          ChoiceChip(
            label: Text('${i + 1}${answered.contains(i) ? ' ✓' : ''}'),
            selected: i == index,
            showCheckmark: false,
            onSelected: (_) => onTap(i),
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.number});

  final AiInterviewQuestion question;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi $number',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandIndigo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppTheme.primaryNavy,
            ),
          ),
          if (question.focus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nhà tuyển dụng đánh giá: ${question.focus}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedText),
            ),
          ],
          if (question.tip.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Gợi ý: ${question.tip}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final AiAnswerFeedback feedback;

  @override
  Widget build(BuildContext context) {
    Widget list(String title, List<String> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('• $item', style: const TextStyle(height: 1.35)),
          ),
      ],
    );

    return Container(
      key: const ValueKey('practice-feedback'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.indigoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${feedback.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nhận xét của AI (thang 10)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          if (feedback.strengths.isNotEmpty)
            list('Điểm mạnh', feedback.strengths),
          if (feedback.improvements.isNotEmpty)
            list('Cần cải thiện', feedback.improvements),
          const SizedBox(height: 10),
          const Text(
            'Câu trả lời gợi ý',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SelectableText(
            feedback.sampleAnswer,
            style: const TextStyle(height: 1.45, color: AppTheme.primarySlate),
          ),
        ],
      ),
    );
  }
}
