## 1.0.0

-    Initial version.

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

## 1.6.1 - 2023/05/31

This version expose the access token. The goal was to get benefit of the authorization features of Directus in order to get files.

### Changed

-    `DirectusAPIMAnager.accessToken` is now readable
-    `DirectusAPIMAnager.shouldRefreshToken` is now readable
-    `DirectusAPIMAnager.tryAndRefreshToken()` can now be trigger by your app

## 1.6.2 - 2023/06/24

This version add some new features :

-    the directus file can be upload to the specify storage
-    the `Directus Data` has a new getter bool `hasChangedIn({required String forKey})` which allow to know if the property has been changed.
-

Bug Fix :

-    the multi delete file function was not able to delete files.

## 1.7.0 - 2023/06/29

This version add some new features :

-    expose the refresh token
