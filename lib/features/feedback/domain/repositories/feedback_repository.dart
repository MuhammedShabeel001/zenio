import 'dart:convert';
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
      throw Exception(
        'Feedback webhook URL is not configured. Please provide your Google Apps Script Web App URL.',
      );
    }

    try {
      final response = await _dio.post<dynamic>(
        _webhookUrl.trim(),
        data: jsonEncode(feedback.toJson()),
        options: Options(
          contentType: Headers.textPlainContentType,
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 302) {
        throw Exception(
          'Failed to submit feedback (status: ${response.statusCode})',
        );
      }

      final responseBody = response.data?.toString() ?? '';
      if (responseBody.contains('accounts.google.com') ||
          responseBody.contains('ServiceLogin') ||
          responseBody.contains('Page not found') ||
          responseBody.contains('unable to open the file')) {
        throw Exception(
          'Google Apps Script permission error: Please set "Who has access" to "Anyone" in the Web App deployment settings.',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.error.toString().contains('Failed host lookup') ||
          e.error.toString().contains('SocketException') ||
          (e.message?.contains('Failed host lookup') ?? false)) {
        throw Exception(
          'Unable to reach the server. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timed out. Please check your network and try again.',
        );
      }
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Network error occurred while submitting feedback.',
      );
    } catch (e) {
      rethrow;
    }
  }
}
