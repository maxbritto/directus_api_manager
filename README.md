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

For each directus model, create a new class that inherits `DirectusItem` and use annotations to specify the èndpointName`:

```dart
@DirectusCollection()
@CollectionMetadata(endpointName: "player")
class PlayerDirectusModel extends DirectusItem {
}
```

This `endpointName` is the name of the collection in Directus : use the exact same name you used when creating your directus collection, including capitalized letters.

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

The _key_ is the name of the property in your directus collection, you must use the same types in your directus collection as in your Dart computed properties.

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

-    authentication and token management
-    sending request
-    parsing responses
-    etc.

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
} else if (result.type == DirectusLoginResultType.invalidOTP) {
  print("Please provide OTP");
  // Keep email and password for the next screen or extra field and resumit using
  // await apiManager.loginDirectusUserWithOtp("will@acn.com", "will-password", "123456");
} else if (result.type == DirectusLoginResultType.error) {
  print("An unknown error occured");
  final additionalMessage = result.message;
  if (additionalMessage != null) {
    print("More information : $additionalMessage");
  }
}
```

If the user's login requires MFA/OTP, you should present an extra field or page to the user to complete, and resend the authentification to the `loginDirectusUserWithOtp` method:

```dart
final result = await apiManager.loginDirectusUserWithOtp("will@acn.com", "will-password", "123456");
```

All future request of this `apiManager` instance will include this user token.

### CRUD for your collections

For each collection you can either :

-    fetch one or multiple items
-    update items
-    create items
-    delete items

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

## Web Socket support

### DirectusWebSocket

`DirectusWebSocket` allow to consume data from Directus via a WebSocket. It will handle the authentication, the refresh token process and keep the connection alive. Each `DirectusWebSocket` can have more than one `DirectusWebSocketSubscription`.

### DirectusWebSocketSubscription

`DirectusWebSocketSubscription` represent a subscription to your Directus server. Here are the mandatory properties to use it :

-    `uid` must be specified. When the server will send a message, this uid will be provided. This allow us to know from which subscription this message came from.
-    `onCreate`, `onUpdate`, `onDelete` callbacks are trigger when a subscription receive a subscription message. They are all optional but the `DirectusWebSocketSubscription` must have at least one of them.

```dart
DirectusWebSocketSubscription<DirectusDataExtension>(
        uid: "directus_data_extension_uid",
        onCreate: onCreate,
        onUpdate: onUpdate,
        onDelete: onDelete,
        sort: const [SortProperty("id")],
        limit: 10,
        offset: 10
        filter: const PropertyFilter(
            field: "folder",
            operator: FilterOperator.equals,
            value: "folder_id"));
```

## Cache system

### Enabling and configuring the Cache system

This api comes with a caching system that can be enabled by providing an instance of `ILocalDirectusCacheInterface` when creating your `DirectusApiManager` instance.

Currently 2 ready to use implementations are provided :

- The `JsonCacheEngine` class will store the data in a folder of your choosing using json files.
- The `MemoryCacheEngine` class will store the data in memory only. If you use it inside a Flutter app, the cache will emptied on each app restart

Example : 

```dart
import 'package:path_provider/path_provider.dart';

void main() async {
  final directory = await getApplicationCacheDirectory();
  final apiManager = DirectusApiManager(baseURL: "http://0.0.0.0:8055/", cacheEngine: JsonCacheEngine(cacheFolderPath: "${directory.path}/directus_api_cache"));
  // ...
}
```
You can decide to replace the json file implementation by creating and supplying your own implementation which implements the `ILocalDirectusCacheInterface` class.

### Using the Cache system for your requests

All read requests (get, find, currentUser, etc.) now have optional parameters to configure the cache. By default, most of those will save responses but will only use those if the next request fails.
If you want to also replace future responses by a local cache read, you can set the `canUseCacheForResponse` parameter to `true` and tweak the `maxCacheAge` parameter to set the maximum age of the cache (defaults to 1 day). This will prevent calling the directus server if a valid cache exists for the same request.

```dart
await apiManager.getSpecificItem<DirectusItemTest>(
    id: "element1",
    canUseCacheForResponse: true,
    maxCacheAge: const Duration(days: 1));
```

If you want to disable the cache completely for a request, you can set the `canSaveResponseToCache` parameter to `false`.

```dart
await apiManager.getSpecificItem<DirectusItemTest>(
    id: "element1",
    canSaveResponseToCache: false);
```

By default, an expired cache can still be used if the real network request fails. If you want to disable this behavior, you can set the `canUseOldCachedResponseAsFallback` parameter to `false`.

```dart
await apiManager.getSpecificItem<DirectusItemTest>(
    id: "element1",
    canUseOldCachedResponseAsFallback: false);
```

Those parameters are available for all read based requests.

### Clearing the cache before it expires

The engine tries to be smart and will regularly invalidate caches when it performs modifications on the same type of data. For example :
- if you create a new item, the cache for the list of items will be invalidated.
- If you update an item, the cache for this specific item will be invalidated, as long as any list for that type of object. 
- If you delete an item, the cache for this specific item will be invalidated, as long as any list for that type of object.

We suggest you rely mostly on automatic cache invalidation, but you can also manually clear the cache for specific requests.

#### Clearing cache for a specific object

You can use the [clearCacheForObject] function to clear the cache for a specific object. The object must be of type extending `DirectusData`.
If you only have the id of the object, you can use the [clearCacheForObjectWithId] function with the type hinted :

```dart
await apiManager.clearCacheForObjectWithId<DirectusItemTest>("element1");
```

#### Clearing the current user cache

The current user is a specific cache and for it, you can use the [discardCurrentUserCache] function.

#### Clearing all caches

Logging out the current user will automatically clear all the cached data. 

#### Clearing specific caches with the cache key

Each cached object has a key that is used to store and retrieve it. This key is usually generated automatically based on the request, but you can provide your own cache key with the `requestIdentifier` parameter available on every `read` based method. 

```dart
await apiManager.getSpecificItem<DirectusItemTest>(
    id: "element1",
    requestIdentifier: "my_custom_key");
```

Then you can use the [clearCacheWithKey] function to clear the cache associated with this key.

```dart
await apiManager.clearCacheWithKey("my_custom_key");
```

#### Clearing specific caches with tags

You can associate a set of tags with every read you perform. Those tags will be associated with the cached data, and can be use to invalidate those before the cache expiration time. 

```dart
await sut.getSpecificItem<DirectusItemTest>(
    id: "element1",
    extraTags: ["tag1", "tag2"]);
await sut.getSpecificItem<DirectusItemTest>(
    id: "element2",
    extraTags: ["tag3"]);
await sut.getSpecificItem<DirectusItemTest>(
    id: "element3",
    extraTags: ["tag2", "tag4"]);

```
Those parameters are available for all read based requests.

Then you can use the [removeCacheEntriesWithTags] function to clear the caches entries associated with those tags.

```dart
await apiManager.removeCacheEntriesWithTags(["tag1", "tag3"]); //this will invalidate element1 and element2 from the example above
```

You can also use the `List<String> extraTagsToClear` parameter present in each modification based method (create, update, delete) to clear the cache associated with those tags if the call succeeds.

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
Here is an example of a properties of type _Tag list_ in Directus, inside we can enter some courses ids as number but Directus consider all tags as Strings. So we convert them in the dart code like this :

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
