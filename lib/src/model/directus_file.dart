import 'package:directus_api_manager/directus_api_manager.dart';

@DirectusCollection()
@CollectionMetadata(
    endpointName: "files",
    endpointPrefix: "/",
    webSocketEndPoint: "directus_files")
class DirectusFile extends DirectusData {
  static String? baseUrl;

  String? get title => getValue(forKey: "title");
  String? get type => getValue(forKey: "type");
  DateTime? get uploadedOn => getOptionalDateTime(forKey: "uploaded_on");
  int? get fileSize => getValue(forKey: "filesize");
  int? get width => getValue(forKey: "width");
  int? get height => getValue(forKey: "height");
  int? get duration => getValue(forKey: "duration");
  String? get description => getValue(forKey: "description");
  Map<String, dynamic>? get metadata => getValue(forKey: "metadata");

  DirectusFile(super.rawReceivedData);
  DirectusFile.fromId(String id, {String? title})
      : super({"id": id, "title": title});

  @Deprecated("message: Use DirectusFile instead")
  DirectusFile.fromJSON(super.jsonData);

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

  double get ratio {
    if (width == null || height == null) {
      return 1;
    }
    return width! / height!;
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
