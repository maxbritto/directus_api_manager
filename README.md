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

TODO: List what your package can do. Maybe include images, gifs, or videos.

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
For each directus model, create a new class that inherits `DirectusItem`.

```dart
class PlayerDirectusModel extends DirectusItem {
}
```
This new class needs to override a getter `endpointName` which is the name of the collection in Directus : return the exact same name you used when creating your directus collection, including capitalized letters.
```dart
@override
String get endpointName => "player";
```

If you intend to fetch data from your server using this model, you must include the init method that calls the one from `super` and passes the raw received data.
```dart
PlayerDirectusModel(super.rawReceivedData);
```

If you intend to create new items and send them to your server, you ust overrode the secondary init method named `newItem()` :
```dart
PlayerDirectusModel.newItem() : super.newItem();
```

Add any property you need as computed property using inner functions to access your data :
```dart
String get nickname => getValue(forKey: "nickname");
int get bestScore => getValue(forKey: "best_score");
```
The *key* is the name of the property in your directus collection, you must use the same types in your directus collection as in your Dart computed properties.

### Create your services

For each model you created, create an associated service : `PlayerDirectusService` will be used to manipulate all your `PlayerDirectusModel` objects (fetch, create, update, delete) :
```dart
class PlayerDirectusService extends DirectusService<PlayerDirectusModel> {
  PlayerDirectusService({required super.apiManager, required super.typeName});

  @override
  PlayerDirectusModel fromDirectus(rawData) {
    return PlayerDirectusModel(rawData);
  }
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
final result = await _directusApiManager.loginDirectusUser("will@acn.com", "will-password");
if (result.type == DirectusLoginResultType.success) {
  print("User logged in");
} else if (result.type == DirectusLoginResultType.invalidCredentials) {
  print("Please verify entered credentials");
} else if (result.type == DirectusLoginResultType.error) {
  print("An unknown error occured");
  final additionalMessage = result.message;
  if (additionalMessage != null) {
    print("More information : " + additionalMessage)
  }
}
```

All future request will include this user token.

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
