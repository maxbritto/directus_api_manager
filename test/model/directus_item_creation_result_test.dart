import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group('DirectusItemCreationResult', () {
    test('Creating DirectusItemCreationResult', () {
      expect(
          () => DirectusItemCreationResult(isSuccess: true), returnsNormally);
      expect(
          () => DirectusItemCreationResult(
              isSuccess: false,
              error: DirectusApiError(customMessage: "hello world")),
          returnsNormally);
      expect(
          () => DirectusItemCreationResult(isSuccess: false), throwsException);
    });

    test("CreatedList empty", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      expect(sut.createdItem, null);
    });

    test("CreatedList contains one item", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      sut.createdItemList.add("a");
      expect(sut.createdItem, "a");
    });

    test("CreatedList contains more than on item", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      sut.createdItemList.add("a");
      sut.createdItemList.add("b");
      expect(sut.createdItem, "a");
    });
  });
}
