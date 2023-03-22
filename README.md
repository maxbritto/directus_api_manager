<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Communicate with a Directus server using its REST API.

## Features

This packages can generate model classes for your each of your Directus collections.

## Install

Add the package as a dependency in your pubspec.yaml file

```yaml
dependencies:
  flutter:
    sdk: flutter

  directus_api_manager:
    git: https://github.com/maxbritto/directus_api_manager.git
```

## Getting started

### Create your models
For each directus model, create a new class that inherits `DirectusItem`.and use annotations to specify the èndpointName`:

```dart
@DirectusCollection()
@CollectionMetadata(endpointName: "player")
class PlayerDirectusModel extends DirectusItem {
}
```
This `endpointName`  is the name of the collection in Directus : use the exact same name you used when creating your directus collection, including capitalized letters.

**Important :** You must include the init method that calls the one from `super` and passes the raw received data, without adding any other parameter.
```dart
PlayerDirectusModel(super.rawReceivedData);
```

You can create other named constructors if you want.
If you intend to create new items and send them to your server, you should override the secondary init method named `newItem()` :
```dart
PlayerDirectusModel.newItem() : super.newItem();
```

Add any property you need as computed property using inner functions to access your data :
```dart
String get nickname => getValue(forKey: "nickname");

int get bestScore => getValue(forKey: "best_score");
set bestScore(int newBestScore) =>
      setValue(newBestScore, forKey: "best_score");
```
The *key* is the name of the property in your directus collection, you must use the same types in your directus collection as in your Dart computed properties.

## Generate the code for your models
Every time you add a new collection, you can trigger the generator for your project:
In your project folder, execute this line :
```bash
dart run build_runner build lib
```
It will add new `.reflectable.dart` files in your projects : do not include those files in your git repository.
**Tip :** Add this line at the end of your `.gitignore` file :
```
*.reflectable.dart
```

## Inititalize the library to use the generated models
```dart
void main() {
  initializeReflectable();
  //...
  // rest of your app
}
```

### Create your DirectusApiManager
This object is the one that will handle everything for you :
- authentication and token management
- sending request
- parsing responses
- etc.
You should only create one object of this type and it only requires the url of your Directus instance :
```dart
DirectusApiManager _directusApiManager = DirectusApiManager(baseURL: "http://0.0.0.0:8055/");
```

### Manage users and Authentication
To authenticate use the `loginDirectusUser` method before making request that needs to be authorized:
```dart
final apiManager = DirectusApiManager(baseURL: "http://0.0.0.0:8055/");
final result = await apiManager.loginDirectusUser("will@acn.com", "will-password");
if (result.type == DirectusLoginResultType.success) {
  print("User logged in");
} else if (result.type == DirectusLoginResultType.invalidCredentials) {
  print("Please verify entered credentials");
} else if (result.type == DirectusLoginResultType.error) {
  print("An unknown error occured");
  final additionalMessage = result.message;
  if (additionalMessage != null) {
    print("More information : $additionalMessage");
  }
}
```
All future request of this `apiManager` instance will include this user token.

### CRUD for your collections
For each collection you can either :
- fetch one or multiple items
- update items
- create items
- delete items

## Creating new items
```dart
final newPlayer = PlayerDirectusModel.newItem(nickname: "Sheldon");
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
```

## Fetching existing items
```dart
//Multiple items
final list = await apiManager.findListOfItems<PlayerDirectusModel>();
for (final player in list) {
  print("${player.nickname} - ${player.bestScore}");
}

//One specific item from an ID
final PlayerDirectusModel onePlayer = await apiManager.getSpecificItem(id: "1");
print(onePlayer.nickname);
```

## Update existing items
```dart
final PlayerDirectusModel onePlayer = await apiManager.getSpecificItem(id: "1");
onePlayer.bestScore = 123;
final updatedPlayer = await apiManager.updateItem(objectToUpdate: onePlayer);
```

## Additional information

### Install

If you want to use a specific version, it can be done in addition to the git ur:
```yaml
  directus_api_manager:
    git: https://github.com/maxbritto/directus_api_manager.git
    version: ^1.2.0
```

### Advanced properties :
If your collections have advanced properties that needs specific parsing you can do it in the computed properties.
Here is an example of a properties of type *Tag list* in Directus, inside we can enter some courses ids as number but Directus consider all tags as Strings. So we convert them in the dart code like this :
```dart
List<int> get requiredCourseIdList {
  final courseListJson = getValue(forKey: "required_course_id_list");
  if (courseListJson is List<dynamic>) {
    return courseListJson
        .map<int>((courseIdString) => int.parse(courseIdString))
        .toList();
  } else {
    return [];
  }
}
```
