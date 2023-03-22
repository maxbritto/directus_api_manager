import 'package:reflectable/reflectable.dart';

class DirectusCollection extends Reflectable {
  const DirectusCollection()
      : super(metadataCapability, newInstanceCapability, declarationsCapability,
            libraryCapability);
}

class CollectionMetadata {
  final String endpointName;
  final String defaultFields;

  const CollectionMetadata(
      {required this.endpointName, this.defaultFields = "*"});
}

class PropertyMetadata {
  final String fieldName;

  const PropertyMetadata({required this.fieldName});
}
