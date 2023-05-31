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
