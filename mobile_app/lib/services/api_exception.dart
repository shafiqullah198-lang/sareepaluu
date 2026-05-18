import 'package:dio/dio.dart';

/// Typed exception for all API errors.
///
/// Use [ApiException.fromDioException] to convert a [DioException] into a
/// user-friendly, typed error you can safely surface in the UI.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  final String message;
  final ApiErrorType type;
  final int? statusCode;

  // ── Factory ──────────────────────────────────────────────────────────────

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message:
              'Connection timed out. Check your network and ensure the server is running.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.connectionError:
        final msg = e.message ?? '';
        if (msg.contains('SocketException') ||
            msg.contains('Connection refused') ||
            msg.contains('Network is unreachable')) {
          return const ApiException(
            message:
                'Cannot reach the server. Make sure Django is running on '
                '0.0.0.0:8000 and your device can access it.',
            type: ApiErrorType.socket,
          );
        }
        return ApiException(
          message: 'Connection error: ${e.message ?? "unknown"}',
          type: ApiErrorType.socket,
        );

      case DioExceptionType.badResponse:
        return ApiException.fromResponse(e.response);

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'SSL certificate error. Use HTTP for local development.',
          type: ApiErrorType.unknown,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          type: ApiErrorType.unknown,
        );

      case DioExceptionType.unknown:
        final msg = e.message ?? '';
        // CORS errors on web surface as generic "unknown" DioExceptions
        if (msg.contains('XMLHttpRequest') || msg.contains('CORS')) {
          return const ApiException(
            message:
                'CORS error: the server rejected the request from this origin. '
                'Check Django CORS_ALLOWED_ORIGINS.',
            type: ApiErrorType.cors,
          );
        }
        return ApiException(
          message: 'Unexpected error: $msg',
          type: ApiErrorType.unknown,
        );
    }
  }

  factory ApiException.fromResponse(Response? response) {
    if (response == null) {
      return const ApiException(
        message: 'Server returned an empty response.',
        type: ApiErrorType.serverError,
      );
    }

    final status = response.statusCode ?? 0;
    final data = response.data;

    // Try to extract a human-readable message from DRF error envelopes
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ??
          data['detail'] as String? ??
          _flattenErrors(data['errors']);
    }

    switch (status) {
      case 400:
        return ApiException(
          message: serverMessage ?? 'Invalid request. Please check your input.',
          type: ApiErrorType.badRequest,
          statusCode: status,
        );
      case 401:
        return ApiException(
          message: serverMessage ?? 'Session expired. Please log in again.',
          type: ApiErrorType.unauthorized,
          statusCode: status,
        );
      case 403:
        return ApiException(
          message: serverMessage ?? 'Access denied.',
          type: ApiErrorType.forbidden,
          statusCode: status,
        );
      case 404:
        return ApiException(
          message: serverMessage ?? 'Resource not found.',
          type: ApiErrorType.notFound,
          statusCode: status,
        );
      case 422:
        return ApiException(
          message: serverMessage ?? 'Unprocessable data.',
          type: ApiErrorType.badRequest,
          statusCode: status,
        );
      default:
        return ApiException(
          message: serverMessage ?? 'Server error ($status). Try again later.',
          type: ApiErrorType.serverError,
          statusCode: status,
        );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _flattenErrors(dynamic errors) {
    if (errors == null) return null;
    if (errors is String) return errors;
    if (errors is List) return errors.join(', ');
    if (errors is Map) {
      return errors.values
          .expand((v) => v is List ? v : [v])
          .join(', ');
    }
    return errors.toString();
  }

  @override
  String toString() => 'ApiException[$type]: $message';
}

enum ApiErrorType {
  timeout,
  socket,
  cors,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  serverError,
  unknown,
}
