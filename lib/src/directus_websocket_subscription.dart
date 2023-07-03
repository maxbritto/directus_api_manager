import 'dart:convert';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';
import 'metadata_generator.dart';
import 'package:reflectable/reflectable.dart';

class DirectusWebSocketSubscription<Type extends DirectusData> {
  final String collection;
  final List<String>? fields;
  final Filter? filter;
  final List<SortProperty>? sort;
  final String? uid;
  final int? limit;
  final int? offset;

  final MetadataGenerator _metadataGenerator = MetadataGenerator();

  DirectusWebSocketSubscription(
      {required this.collection,
      this.fields,
      this.filter,
      this.sort,
      this.uid,
      this.limit,
      this.offset});

  CollectionMetadata _collectionMetadataFromClass(ClassMirror collectionType) {
    final CollectionMetadata collectionMetadata = collectionType.metadata
            .firstWhere((element) => element is CollectionMetadata)
        as CollectionMetadata;

    return collectionMetadata;
  }

  String toJson() {
    Map<String, Object> result = {
      "type": "subscribe",
      "collection": collection,
    };
    List<String> fieldsAsJson = fieldsToJson;
    Map<String, dynamic>? filterAsJson = filterToJson;

    final Map<String, dynamic> query = {};
    query["fields"] = fieldsAsJson;

    if (filterAsJson != null) {
      query["filter"] = filterAsJson;
    }

    if (sort != null && sort!.isNotEmpty) {
      query["sort"] =
          sort!.map((e) => e.ascending ? e.name : "-${e.name}").toList();
    }

    result["query"] = query;

    if (limit != null) {
      query["limit"] = limit;
    }

    if (offset != null) {
      query["offset"] = offset;
    }

    if (uid != null) {
      result["uid"] = uid!;
    }

    return jsonEncode(result).replaceAll(" ", "").replaceAll("\\", "");
  }

  List<String> get fieldsToJson {
    if (fields != null) {
      return fields!;
    }

    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);

    return collectionMetadata.defaultFields.split(",");
  }

  Map<String, dynamic>? get filterToJson {
    if (filter == null) {
      return null;
    }

    return filter!.asMap;
  }
}
