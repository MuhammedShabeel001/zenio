enum FeedbackSubmissionStatus { initial, submitting, success, error }

class FeedbackState {
  const FeedbackState({
    this.status = FeedbackSubmissionStatus.initial,
    this.errorMessage,
  });

  final FeedbackSubmissionStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == FeedbackSubmissionStatus.submitting;
  bool get isSuccess => status == FeedbackSubmissionStatus.success;
  bool get isError => status == FeedbackSubmissionStatus.error;

  FeedbackState copyWith({
    FeedbackSubmissionStatus? status,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
