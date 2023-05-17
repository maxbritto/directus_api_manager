import 'dart:convert';

import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group(
    "DirectusFile",
    () {
      test(
        "Create from JSON",
        () {
          const jsonData = """
                          {
                            "id": "4f4b14fa-a43a-46d0-b7ad-90af5919bebb",
                            "storage": "local",
                            "filename_disk": "4f4b14fa-a43a-46d0-b7ad-90af5919bebb.jpeg",
                            "filename_download": "paulo-silva-vSRgXtQuns8-unsplash.jpg",
                            "title": "Paulo Silva (via Unsplash)",
                            "type": "image/jpeg",
                            "folder": null,
                            "uploaded_by": "0bc7b36a-9ba9-4ce0-83f0-0a526f354e07",
                            "uploaded_on": "2021-02-04T11:37:41",
                            "modified_by": null,
                            "modified_on": "2021-02-04T11:37:42",
                            "filesize": 3442252,
                            "width": 3456,
                            "height": 5184,
                            "duration": null,
                            "description": null,
                            "location": null,
                            "tags": ["photo", "pretty"],
                            "metadata": {
                              "icc": {
                                "version": "2.1",
                                "intent": "Perceptual",
                                "cmm": "lcms",
                                "deviceClass": "Monitor",
                                "colorSpace": "RGB",
                                "connectionSpace": "XYZ",
                                "platform": "Apple",
                                "creator": "lcms",
                                "description": "c2",
                                "copyright": ""
                              }
                            }
                          }
          """;
          final sut = DirectusFile(jsonDecode(jsonData));
          expect(sut.id, "4f4b14fa-a43a-46d0-b7ad-90af5919bebb");
          expect(sut.title, "Paulo Silva (via Unsplash)");
          expect(sut.type, "image/jpeg");
          expect(sut.uploadedOn, DateTime(2021, 2, 4, 11, 37, 41));
          expect(sut.fileSize, 3442252);
          expect(sut.width, 3456);
          expect(sut.height, 5184);
          expect(sut.description, isNull);
        },
      );

      test("Get download url", () {
        DirectusFile.baseUrl = "https://www.base.com";
        final DirectusFile sut = DirectusFile({"id": "123-abc"});
        expect(sut.getDownloadURL(), "https://www.base.com/assets/123-abc");
        expect(sut.getDownloadURL(width: 100),
            "https://www.base.com/assets/123-abc?width=100");
        expect(sut.getDownloadURL(width: 100, height: 200),
            "https://www.base.com/assets/123-abc?width=100&height=200");
        expect(sut.getDownloadURL(width: 100, height: 200, quality: 75),
            "https://www.base.com/assets/123-abc?width=100&height=200&quality=75");
        expect(
            sut.getDownloadURL(
                width: 100,
                height: 200,
                quality: 75,
                otherKeys: const {"fit": "cover", "format": "png"}),
            anyOf(
                "https://www.base.com/assets/123-abc?width=100&height=200&quality=75&fit=cover&format=png",
                "https://www.base.com/assets/123-abc?width=100&height=200&quality=75&format=png&fit=cover"));
        expect(
            sut.getDownloadURL(
                otherKeys: const {"fit": "cover", "format": "png"}),
            anyOf("https://www.base.com/assets/123-abc?fit=cover&format=png",
                "https://www.base.com/assets/123-abc?format=png&fit=cover"));
      });
    },
  );
}
