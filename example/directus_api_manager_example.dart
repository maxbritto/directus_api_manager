import 'package:directus_api_manager/directus_api_manager.dart';
import 'directus_api_manager_example.reflectable.dart';

Future<void> main() async {
  initializeReflectable();
  final apiManager = DirectusApiManager(baseURL: "http://0.0.0.0:8055/");

  // Authenticate
  final loginResult =
      await apiManager.loginDirectusUser("admin@example.com", "d1r3ctu5");
  if (loginResult.type == DirectusLoginResultType.success) {
    print("User logged in");
  } else if (loginResult.type == DirectusLoginResultType.invalidCredentials) {
    print("Please verify entered credentials");
  } else if (loginResult.type == DirectusLoginResultType.invalidOTP) {
    print("You need to provide a valid OneTimePassword code");
  } else if (loginResult.type == DirectusLoginResultType.error) {
    print("An unknown error occured");
    final additionalMessage = loginResult.message;
    if (additionalMessage != null) {
      print("More information : $additionalMessage");
    }
  }

  //Create new item
  final newPlayer = PlayerDirectusModel.newItem(nickname: "Leonard");
  final creationResult =
      await apiManager.createNewItem(objectToCreate: newPlayer);
  if (creationResult.isSuccess) {
    print("Created player!");
    final createdPlayer = creationResult.createdItem;
    // depending on your directus server authorization you might not have access to the created item
    if (createdPlayer != null) {
      print("The id of this new player is ${createdPlayer.id}");
    }
  } else {
    final error = creationResult.error;
    if (error != null) {
      print("Error while creating player : $error");
    }
  }

  //Multiple items
  final list = await apiManager.findListOfItems<PlayerDirectusModel>();
  for (final player in list) {
    print("${player.nickname} - ${player.bestScore}");
  }

  final playerId = list.first.id;
  if (playerId == null) {
    print("No player id found");
    return;
  }

  //One specific item from an ID
  final PlayerDirectusModel? fetchedPlayer =
      await apiManager.getSpecificItem(id: playerId);
  if (fetchedPlayer != null) {
    print(fetchedPlayer.nickname);

    //Update item
    fetchedPlayer.bestScore = 123;
    final updatedPlayer =
        await apiManager.updateItem(objectToUpdate: fetchedPlayer);
    print(updatedPlayer.bestScore);
  }

  // Example of using GeoJsonPolygon with intersects_bbox filter
  geoFilterExample();
}

@DirectusCollection()
@CollectionMetadata(endpointName: "player")
class PlayerDirectusModel extends DirectusItem {
  PlayerDirectusModel.newItem({required String nickname}) : super.newItem() {
    setValue(nickname, forKey: "nickname");
  }

  PlayerDirectusModel(super.rawReceivedData);

  String get nickname => getValue(forKey: "nickname");
  int? get bestScore => getValue(forKey: "best_score");
  set bestScore(int? newBestScore) =>
      setValue(newBestScore, forKey: "best_score");
}

// Example of using GeoJsonPolygon with intersects_bbox filter
void geoFilterExample() {
  print('\n=== Geo Filter Example ===');

  // Create a rectangular bounding box
  final rectangle = GeoJsonPolygon.rectangle(
    topLeft: [168.2947501099543, -17.723682144590242],
    bottomRight: [168.29840874403044, -17.727328428851507],
  );

  // Create a polygon from a list of coordinates
  // ignore: unused_local_variable
  final polygon = GeoJsonPolygon.polygon(
    points: [
      [168.2947501099543, -17.723682144590242],
      [168.29840874403044, -17.723682144590242],
      [168.29840874403044, -17.727328428851507],
      [168.2947501099543, -17.727328428851507],
    ],
  );

  // Create a square centered at a specific point
  // ignore: unused_local_variable
  final square = GeoJsonPolygon.squareFromCenter(
    center: [168.29658, -17.725505],
    distanceInMeters: 400, // distance from center in meters
  );

  // Use the GeoJSON polygon with a PropertyFilter for geospatial queries
  final locationFilter = GeoFilter(
      field: "location",
      operator: GeoFilterOperator.intersectsBbox,
      feature: rectangle);

  // You can use this filter in your API queries
  print('Filter JSON: ${locationFilter.asJSON}');

  // Or use it as a Map
  print('Filter Map: ${locationFilter.asMap}');
}
