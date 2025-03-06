import 'dart:convert';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'metadata_generator.dart';
import 'package:reflectable/reflectable.dart';

class DirectusWebSocketSubscription<Type extends DirectusData> {
  final List<String>? fields;
  final Filter? filter;
  final List<SortProperty>? sort;
  final String uid;
  final int? limit;
  final int? offset;

  Function(Map<String, dynamic>)? onCreate;
  Function(Map<String, dynamic>)? onUpdate;
  Function(Map<String, dynamic>)? onDelete;

  /// Function to be called when an error occurs on the socket level. Each subscription on that socket will call this function if provided.
  Function(dynamic)? onError;

  /// Function to be called when the subscription has finished receiving events. This can happen in two cases:
  /// 1 - The unsubcribe event has been sent and acknowledged for this subscription.
  /// 2 - The socket holding this subscription has been closed.
  Function()? onDone;

  String get collection => collectionMetadata.endpointName;

  final MetadataGenerator _metadataGenerator = MetadataGenerator();

  ClassMirror get specificClass =>
      _metadataGenerator.getClassMirrorForType(Type);
  CollectionMetadata get collectionMetadata =>
      _collectionMetadataFromClass(specificClass);

  DirectusWebSocketSubscription(
      {required this.uid,
      this.fields,
      this.filter,
      this.sort,
      this.limit,
      this.offset,
      this.onCreate,
      this.onUpdate,
      this.onDelete,
      this.onError,
      this.onDone}) {
    if (onCreate == null && onUpdate == null && onDelete == null) {
      throw Exception(
          "You must provide at least one callback for onCreate, onUpdate or onDelete");
    }
  }

  CollectionMetadata _collectionMetadataFromClass(ClassMirror collectionType) {
    final CollectionMetadata collectionMetadata = collectionType.metadata
            .firstWhere((element) => element is CollectionMetadata)
        as CollectionMetadata;

    return collectionMetadata;
  }

  String toJson() {
    Map<String, Object> result = {
      "type": "subscribe",
      "collection": collectionMetadata.webSocketEndpoint,
    };

    List<String> fieldsAsJson = fieldsToJson;
    Map<String, dynamic>? filterAsJson = filterToJson;

    final Map<String, dynamic> query = {};
    query["fields"] = fieldsAsJson;

    if (filterAsJson != null) {
      query["filter"] = filterAsJson;
    }

    final sort = this.sort;
    if (sort != null && sort.isNotEmpty) {
      query["sort"] =
          sort.map((e) => e.ascending ? e.name : "-${e.name}").toList();
    }

    result["query"] = query;

    if (limit != null) {
      query["limit"] = limit;
    }

    if (offset != null) {
      query["offset"] = offset;
    }

    result["uid"] = uid;

    return jsonEncode(result).replaceAll(" ", "").replaceAll("\\", "");
  }

  List<String> get fieldsToJson {
    final fields = this.fields;
    if (fields != null) {
      return fields;
    }

    return collectionMetadata.defaultFields.split(",");
  }

  Map<String, dynamic>? get filterToJson {
    final filter = this.filter;
    if (filter == null) {
      return null;
    }

    return filter.asMap;
  }
}
