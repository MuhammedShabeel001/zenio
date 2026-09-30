import 'dart:convert';

/// The result of decoding a stored list: the entries that could be read, and
/// the raw text of those that could not.
class DecodedJsonList<T> {
  const DecodedJsonList(this.items, this.unreadable);

  final List<T> items;
  final List<String> unreadable;
}

/// Decodes a list stored as a JSON array whose entries are JSON-encoded
/// objects (the format every feature has always used).
///
/// Each entry is decoded on its own, so one bad entry never hides the others.
/// If the array itself is unreadable, the whole [raw] value is reported as
/// unreadable.
DecodedJsonList<T> decodeJsonList<T>(
  String raw,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final List<dynamic> entries;
  try {
    entries = jsonDecode(raw) as List<dynamic>;
  } catch (_) {
    return DecodedJsonList<T>(const [], [raw]);
  }

  final items = <T>[];
  final unreadable = <String>[];
  for (final entry in entries) {
    try {
      final map = entry is String ? jsonDecode(entry) : entry;
      items.add(fromJson(map as Map<String, dynamic>));
    } catch (_) {
      unreadable.add(entry is String ? entry : jsonEncode(entry));
    }
  }
  return DecodedJsonList<T>(items, unreadable);
}

/// Encodes [items] in the same format [decodeJsonList] reads.
String encodeJsonList(Iterable<Map<String, dynamic>> items) {
  return jsonEncode(items.map(jsonEncode).toList());
}

/// Adds [entries] to the already preserved [existing] ones, skipping
/// duplicates. Returns null when nothing new was added.
List<String>? mergeUnreadable(List<String> existing, List<String> entries) {
  final merged = [
    ...existing,
    ...entries.where((entry) => !existing.contains(entry)),
  ];
  return merged.length == existing.length ? null : merged;
}

/// Reads a stored JSON array of strings (the format unreadable entries are
/// preserved in). A value that is not such an array is kept as one entry.
List<String> decodeStringList(String raw) {
  try {
    return (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
  } catch (_) {
    return [raw];
  }
}

String encodeStringList(List<String> values) => jsonEncode(values);
