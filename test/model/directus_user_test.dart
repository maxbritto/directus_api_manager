import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group('DirectusUser', () {
    test('Creating an invalid user should throw', () {
      expect(() => DirectusUser({}), throwsException);
      expect(() => DirectusUser({"id": "123-abc"}), throwsException);
      expect(() => DirectusUser({"email": "will@acn.com"}), throwsException);
      expect(() => DirectusUser({"id": "123-abc", "email": "will@acn.com"}),
          returnsNormally);
    });

    test('New User', () {
      final newUser = DirectusUser.newDirectusUser(
          email: "will@acn.com",
          password: "pass123",
          firstname: "Will",
          lastname: "McAvoy",
          roleUUID: "abc-123",
          otherProperties: {"location": "Sète"});
      expect(newUser.email, "will@acn.com");
      expect(newUser.mapForObjectCreation()["password"], "pass123");
      expect(newUser.firstname, "Will");
      expect(newUser.lastname, "McAvoy");
      expect(newUser.roleUUID, "abc-123");
      expect(newUser.getValue(forKey: "location"), "Sète");
    });

    test('User essential properties are retrieved from property list', () {
      final sut = DirectusUser({
        "id": "abc-123",
        "first_name": "Will",
        "last_name": "McAvoy",
        "email": "will@acn.com",
        "avatar": "1"
      });
      expect(sut.id, "abc-123");
      expect(sut.firstname, "Will");
      expect(sut.lastname, "McAvoy");
      expect(sut.email, "will@acn.com");
      expect(sut.avatar, "1");
    });

    test('Extra properties can be added and read', () {
      final sut = DirectusUser({"id": "abc-123", "email": "will@acn.com"});
      sut.setValue("Sète", forKey: "location");
      expect(sut.getValue(forKey: "location"), "Sète");
    });

    test('Reading an undefined property returns null without crashing', () {
      final sut = DirectusUser({"id": "abc-123", "email": "will@acn.com"});
      expect(sut.getValue(forKey: "undefined_property"), null);
      expect(sut.firstname, null);
      expect(sut.lastname, null);
    });

    test('Reading first, last and full name', () {
      final sut = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": "Luke",
        "last_name": "Skywalker"
      });

      expect(sut.firstname, "Luke");
      expect(sut.lastname, "Skywalker");
      expect(sut.fullName, "Luke Skywalker");

      final lastNameEmpty = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": "Luke",
        "last_name": null
      });

      expect(lastNameEmpty.firstname, "Luke");
      expect(lastNameEmpty.lastname, null);
      expect(lastNameEmpty.fullName, "Luke");

      final firstNameEmpty = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": null,
        "last_name": "Skywalker"
      });

      expect(firstNameEmpty.firstname, null);
      expect(firstNameEmpty.lastname, "Skywalker");
      expect(firstNameEmpty.fullName, "Skywalker");

      final firstAndLastNameEmpty = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": null,
        "last_name": null
      });

      expect(firstAndLastNameEmpty.firstname, null);
      expect(firstAndLastNameEmpty.lastname, null);
      expect(firstAndLastNameEmpty.fullName, "");
    });

    test('Convert object properties to map', () {
      final sut = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": "Luke",
        "last_name": "Skywalker"
      });
      Map<String, dynamic> mapResult = sut.mapForObjectCreation();

      expect(mapResult["email"], "luke@skywalker.com");
      expect(mapResult["first_name"], "Luke");
      expect(mapResult["last_name"], "Skywalker");
    });

    test('needsSaving on regular properties', () {
      final sut = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": "Luke",
        "last_name": "Skywalker"
      });
      expect(sut.needsSaving, false);
      sut.firstname = "Luke 2";
      expect(sut.needsSaving, true);
    });

    test('needsSaving on custom properties', () {
      final sut = DirectusUser({
        "id": "abc-123",
        "email": "luke@skywalker.com",
        "first_name": "Luke",
        "last_name": "Skywalker"
      });
      expect(sut.needsSaving, false);
      sut.setValue("new value", forKey: "secretKey");
      expect(sut.needsSaving, true);
    });

    test('Writing default property', () {
      final sut = DirectusUser({"id": "abc-123", "email": "will@acn.com"});
      sut.avatar = "1";
      expect(sut.avatar, "1");
    });
  });
}
