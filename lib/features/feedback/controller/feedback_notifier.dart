import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/feedback/controller/feedback_state.dart';
import 'package:zenio/features/feedback/domain/models/feedback_model.dart';
import 'package:zenio/features/feedback/domain/repositories/feedback_repository.dart';

part 'feedback_notifier.g.dart';

@riverpod
class FeedbackNotifier extends _$FeedbackNotifier {
  @override
  FeedbackState build() {
    return const FeedbackState();
  }

  Future<bool> submit({
    required int star,
    required String category,
    required String mailid,
    required String message,
  }) async {
    state = state.copyWith(
      status: FeedbackSubmissionStatus.submitting,
    );

    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('hh:mm:ss a').format(now);

      final feedback = FeedbackModel(
        date: date,
        time: time,
        mailid: mailid.trim(),
        star: star,
        category: category.trim(),
        message: message.trim(),
      );

      final repo = ref.read(feedbackRepositoryProvider);
      await repo.submitFeedback(feedback);

      state = state.copyWith(status: FeedbackSubmissionStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: FeedbackSubmissionStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const FeedbackState();
  }
}
