import 'package:directus_api_manager/directus_api_manager.dart';

abstract class DirectusService<Type extends DirectusItem> {
  final DirectusApiManager apiManager;
  final String typeName;
  final String fields;
  Type fromDirectus(dynamic rawData);

  DirectusService(
      {required this.apiManager, required this.typeName, this.fields = "*"});

  Future<Iterable<Type>> findListOfItems(
      {Filter? filter,
      List<SortProperty>? sortBy,
      String? fields,
      int? limit,
      int? offset}) {
    return apiManager.findListOfItems(
        name: typeName,
        createItemFunction: fromDirectus,
        fields: fields ?? this.fields,
        filter: filter,
        limit: limit,
        offset: offset,
        sortBy: sortBy);
  }

  Future<Type> getSpecificItem({required String id}) {
    return apiManager.getSpecificItem(
        name: typeName,
        fields: fields,
        id: id,
        createItemFunction: fromDirectus);
  }

  Future<DirectusItemCreationResult<Type>> create(Type objectToCreate) async {
    return apiManager.createNewItem(
        objectToCreate: objectToCreate,
        createItemFunction: fromDirectus,
        fields: fields);
  }

  Future<DirectusItemCreationResult<Type>> createMulti(
      Iterable<Type> objectsToCreate) async {
    return apiManager.createMultipleItems(
        objectList: objectsToCreate, createItemFunction: fromDirectus);
  }

  Future<Type> edit(Type objectToUpdate) async {
    return apiManager.updateItem(
        objectToUpdate: objectToUpdate,
        updateItemFunction: fromDirectus,
        fields: fields);
  }

  Future<bool> delete(Type objectToDelete) async {
    return apiManager.deleteItem(objectToDelete: objectToDelete);
  }

  Future<bool> deleteMulti(List<Type> objectsToDelete) async {
    return apiManager.deleteMultipleItems(objectListToDelete: objectsToDelete);
  }
}
