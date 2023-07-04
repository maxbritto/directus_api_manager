import 'package:reflectable/reflectable.dart';

class DirectusCollection extends Reflectable {
  const DirectusCollection()
      : super(metadataCapability, newInstanceCapability, declarationsCapability,
            libraryCapability);
}

class CollectionMetadata {
  final String endpointName;
  final String endpointPrefix;
  final String defaultFields;
  final String? webSocketEndPoint;

  const CollectionMetadata(
      {required this.endpointName,
      this.defaultFields = "*",
      this.endpointPrefix = "/items/",
      this.webSocketEndPoint});

  String get webSocketEndpoint => webSocketEndPoint ?? endpointName;
}
