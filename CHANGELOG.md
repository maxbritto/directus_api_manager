## 1.9.3 - 2024/12/09
- Make the test 'Creating an invalid user should throw' pass after 1.9.0 implementation of optional email field.

## 1.9.2 - 2024/11/25
- Improved refresh token handling when reloading the app after a long time.

## 1.9.1 - 2024/11/14
- Added new properties that can be used on `DirectusUser` to get/set the user's status. An `UserStatus` enum is provided that matches possible values offered by the Directus team.

## 1.9.0 - 2024/11/04
- Added a new API for registering a new user (which is different from creating a user object in Directus). See https://docs.directus.io/reference/authentication.html#register
- Improved update return : now returns the server returned object and not the one sent to the server.
- User email field is now optional to better reflect what actually happens in Directus. When reading an user object, directus will return the fields the current user has access, if the user doesn't have access to the "email" field then the value will be null.
- Added more convenience init and properties on directus_item and directus_data

## 1.8.2 - 2024/10/08

Added an automatic cache invalidation when updating or deleting any specific item.

## 1.8.1 - 2024/10/08

Bug Fix: Updating the current user was not invalidating the current user caches (variable and cache engine)

## 1.8.0 - 2024/09/27

New feature: local cache and basic offline mode support 🔥

This version offers a ready to use cache engine based on json files. It is disabled by default, check the readme for more information on how to enable and use it in your projects.

## 1.7.7 - 2024/08/21

This version adds a new feature:

- adds the "DirectusGeometryType" class to manage the geometry type of Postgres databases.
- Currently it can load any geometry type from a JSON object
- Currently it exposes convenience constructor and properties for the Point type used in regular geometry (x,y) or in map context (longitude, latitude)
- Add addSubscription and removeSubscription to make the use of websocket more easy

## 1.7.6 - 2024/07/09

This version adds a new feature:

-    expose the DirectusData class
-    expose the baseUrl variable

## 1.7.5 - 2024/03/19

This version adds a new feature:

-    allow to specify the fields that can be updated if there is difference with the fields that can be seen.

## 1.7.4 - 2024/03/14

This version adds a new feature:

-    allow to force item update even if the object has no change

## 1.7.3 - 2024/02/21

This version adds a new feature:

-    add One Time Password login capability

## 1.7.1 - 2023/09/03

Bug Fix :

-    the multi delete items function was not building the request url correctly.

## 1.7.0 - 2023/06/29

This version add some new features :

-    add web socket support
-    expose the refresh token

## 1.6.2 - 2023/06/24

This version add some new features :

-    the directus file can be upload to the specify storage
-    the `Directus Data` has a new getter bool `hasChangedIn({required String forKey})` which allow to know if the property has been changed.
-

Bug Fix :

-    the multi delete file function was not able to delete files.

## 1.6.1 - 2023/05/31

This version expose the access token. The goal was to get benefit of the authorization features of Directus in order to get files.

### Changed

-    `DirectusAPIMAnager.accessToken` is now readable
-    `DirectusAPIMAnager.shouldRefreshToken` is now readable
-    `DirectusAPIMAnager.tryAndRefreshToken()` can now be trigger by your app

## 1.6.0 - 2023/05/31

This version add the DirectusFile class as an extension of DirectusData. This allow us to manage file like other collections.

### Breaking change

-    DirectusFile class extend DirectusData.
-    DirectusFile constructor has been changed to respect DirectusData constructor.
-    `DirectusFile.fromJSON(Map<String, dynamic> jsonData)` is deprecated and replace by `DirectusFile` default constructor
-    DirectusFile has a new constructor to quickly create an object based on his id.
-    `DirectusFile(this.id, {this.title})`has been replaced by `DirectusFile.fromId(String id, {String? title})`

### Additional Changed

-    DirectusFile class as some getters and setters for the default fields of the directus_files table

## 1.0.0

-    Initial version.
