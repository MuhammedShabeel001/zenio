import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/feedback/domain/models/feedback_model.dart';
import 'package:zenio/shared/providers/dio_provider/dio_provider.dart';
import 'package:zenio/shared/providers/env_provider/env_provider.dart';

abstract class IFeedbackRepository {
  Future<void> submitFeedback(FeedbackModel feedback);
}

final feedbackRepositoryProvider = Provider<IFeedbackRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final env = ref.watch(envProvider);
  return FeedbackRepository(dio: dio, webhookUrl: env.FEEDBACK_WEBHOOK_URL);
});

class FeedbackRepository implements IFeedbackRepository {
  FeedbackRepository({
    required Dio dio,
    required String webhookUrl,
  })  : _dio = dio,
        _webhookUrl = webhookUrl;

  final Dio _dio;
  final String _webhookUrl;

  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {
    if (_webhookUrl.trim().isEmpty) {
      _debugLog('Feedback webhook URL is not configured.');
      throw const FeedbackSubmitException(FeedbackSubmitException.unavailable);
    }

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        _webhookUrl.trim(),
        data: jsonEncode(feedback.toJson()),
        options: Options(
          contentType: Headers.textPlainContentType,
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException catch (e) {
      _debugLog('Feedback request failed: ${e.type} ${e.message}');
      throw FeedbackSubmitException(switch (e.type) {
        DioExceptionType.connectionError => FeedbackSubmitException.offline,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          FeedbackSubmitException.timedOut,
        _ => FeedbackSubmitException.unavailable,
      },);
    }

    final body = response.data?.toString() ?? '';
    // Google Apps Script answers 200 with a sign-in or error page when the
    // web app is misconfigured; that is a server problem, not the user's.
    if ((response.statusCode != 200 && response.statusCode != 302) ||
        body.contains('accounts.google.com') ||
        body.contains('ServiceLogin') ||
        body.contains('Page not found') ||
        body.contains('unable to open the file')) {
      _debugLog('Feedback endpoint rejected the request '
          '(status ${response.statusCode}).');
      throw const FeedbackSubmitException(FeedbackSubmitException.unavailable);
    }
  }

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}

/// A feedback submission failure, with a message that can be shown as is.
class FeedbackSubmitException implements Exception {
  const FeedbackSubmitException(this.message);

  static const String offline =
      "You're offline. Check your connection and try again.";
  static const String timedOut =
      'The connection timed out. Please try again.';
  static const String unavailable =
      "Feedback can't be sent right now. Please try again later.";

  final String message;

  @override
  String toString() => message;
}
