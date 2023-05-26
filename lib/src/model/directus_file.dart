class DirectusFile {
  static String? baseUrl;
  final String id;
  final String? title;

  DirectusFile.fromJSON(Map<String, dynamic> jsonData)
      : id = jsonData["id"],
        title = jsonData["title"];

  const DirectusFile(this.id, {this.title});

  /// Builds an URL to download this file
  /// `DirectusFile.baseUrl` must have been filled at least once before calling this function.
  /// If you're using this library, this should have been done automatically when creating the `DirectusApiManager`
  String getDownloadURL(
      {int? width,
      int? height,
      int? quality,
      Map<String, String> otherKeys = const {}}) {
    assert(baseUrl != null);
    final buffer = StringBuffer("${baseUrl!}/assets/$id");
    final extras = <String>[];

    if (width != null) {
      extras.add("width=$width");
    }
    if (height != null) {
      extras.add("height=$height");
    }
    if (quality != null) {
      extras.add("quality=$quality");
    }
    for (final extraEntry in otherKeys.entries) {
      extras.add("${extraEntry.key}=${extraEntry.value}");
    }
    if (extras.isNotEmpty) {
      buffer.write("?");
      buffer.writeAll(extras, "&");
    }

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectusFile &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          id == other.id;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
