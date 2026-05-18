// ─── List / pagination helpers ────────────────────────────────────────────────

/// Extracts the results list from a DRF paginated response or plain list.
/// Handles: { "results": [...] }  |  [ ... ]  |  anything else → []
List<dynamic> resultsOf(dynamic data) {
  if (data is Map<String, dynamic> && data['results'] is List) {
    return data['results'] as List<dynamic>;
  }
  if (data is List) return data;
  return const [];
}

// ─── Safe type conversion ─────────────────────────────────────────────────────

/// Safely parse any JSON value (num, String, null) to double.
double safeDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely parse any JSON value (num, String, null) to int.
int safeInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

// ─── Error envelope helpers ───────────────────────────────────────────────────

/// Extracts a human-readable message from a DRF error envelope.
///
/// DRF returns errors in various shapes:
///   { "message": "..." }
///   { "detail": "..." }
///   { "errors": { "field": ["msg"] } }
///   { "errors": ["msg1", "msg2"] }
///   "plain string"
String? extractError(dynamic data) {
  if (data == null) return null;
  if (data is String) return data.isNotEmpty ? data : null;

  if (data is Map<String, dynamic>) {
    final msg = data['message'] as String?;
    if (msg != null && msg.isNotEmpty) return msg;

    final detail = data['detail'] as String?;
    if (detail != null && detail.isNotEmpty) return detail;

    final errors = data['errors'];
    if (errors != null) return _flattenErrors(errors);
  }

  return null;
}

String? _flattenErrors(dynamic errors) {
  if (errors == null) return null;
  if (errors is String) return errors.isNotEmpty ? errors : null;
  if (errors is List) {
    final parts = errors.map((e) => e.toString()).where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
  if (errors is Map) {
    final parts = errors.entries.map((entry) {
      final val = entry.value;
      final valStr = val is List
          ? val.map((v) => v.toString()).join(', ')
          : val.toString();
      return '${entry.key}: $valStr';
    });
    return parts.isNotEmpty ? parts.join(' | ') : null;
  }
  return errors.toString();
}
