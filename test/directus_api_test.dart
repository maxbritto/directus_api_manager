import 'dart:convert';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  const defaultAccessToken = "ABCD.1234.ABCD";
  const defaultRefreshToken = "DEFAULT.REFRESH.TOKEN";
  DirectusAPI makeAuthenticatedDirectusAPI() {
    final directusApi = DirectusAPI("http://api.com");
    final response = Response(
        '{"data":{"access_token":"$defaultAccessToken","expires":900000,"refresh_token":"$defaultRefreshToken"}}',
        200);
    directusApi.parseLoginResponse(response);
    return directusApi;
  }

  group("DirectusAPI Getter", () {
    test("Get access token", () {
      final sut = makeAuthenticatedDirectusAPI();
      expect(sut.accessToken, "ABCD.1234.ABCD");
      expect(sut.shouldRefreshToken, false);
    });

    test("shouldRefreshToken - when loadable from backup", () {
      final sut = DirectusAPI("http://api.com",
          loadRefreshTokenCallback: () async => "LOADED.TOKEN");
      expect(sut.shouldRefreshToken, true,
          reason: "Refresh token can be loaded, we should try it");
    });
  });

  group("DirectusAPI Data Management", () {
    test('Get list of items request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article", endpointPrefix: "/items/", fields: "*.*");
      expect(request.request.url.toString(),
          "http://api.com/items/article?fields=*.*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"));
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with sort and filter request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          sortBy: [
            SortProperty("score", ascending: false),
            SortProperty("level")
          ],
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"));
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&sort=-score,level');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with sort request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          sortBy: [
            SortProperty("score", ascending: false),
            SortProperty("level")
          ]);
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&sort=-score,level');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article", endpointPrefix: "/items/", limit: 10);
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&limit=10');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter and limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"),
          limit: 10);
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&limit=10');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with offset request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article", endpointPrefix: "/items/", offset: 10);
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&offset=10');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter, sort and limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"),
          sortBy: [
            SortProperty("score", ascending: false),
            SortProperty("level")
          ],
          limit: 10);
      expect(request.request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&limit=10&sort=-score,level');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter that includes special characters', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "article",
          endpointPrefix: "/items/",
          filter: PropertyFilter(
              field: "date",
              operator: FilterOperator.between,
              value: [r"$NOW", r"$NOW(+2 weeks)"]));
      expect(request.request.url.toString(),
          r'http://api.com/items/article?fields=*&filter=%7B+%22date%22%3A+%7B+%22_between%22%3A+%5B%22%24NOW%22%2C%22%24NOW%28%2B2+weeks%29%22%5D+%7D%7D');
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get specific item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetSpecificItemRequest(
          endpointName: "article",
          itemId: "123",
          endpointPrefix: "/items/",
          tags: ["tag1", "tag2"]);
      expect(request.request.url.toString(),
          "http://api.com/items/article/123?fields=*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
      expect(request.tags, ["tag1", "tag2"]);
    });

    test('Get specific item request with deep fields', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetSpecificItemRequest(
        endpointName: "article",
        endpointPrefix: "/items/",
        itemId: "123",
        fields: "*.*",
      );
      expect(request.request.url.toString(),
          "http://api.com/items/article/123?fields=*.*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('New Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateNewItemRequest(
          endpointName: "articles",
          endpointPrefix: "/items/",
          objectData: {
            "title": "Let's dance",
            "pageCount": 10,
            "creationDate": DateTime(2022, 1, 2, 3, 4, 5)
          },
          fields: "*.*");
      expect(request.request.url.toString(),
          "http://api.com/items/articles?fields=*.*");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["title"], "Let's dance");
      expect(jsonParsedBody["pageCount"], 10);
      expect(jsonParsedBody["creationDate"], "2022-01-02T03:04:05.000");
    });

    test("register user request", () {
      final sut = DirectusAPI("http://api.com");
      final request = sut.prepareRegisterUserRequest(
          email: "will@acn.com",
          password: "mc!avoy",
          firstname: "Will",
          lastname: "McAvoy");
      expect(request.request.url.toString(), "http://api.com/users/register");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "mc!avoy");
      expect(jsonParsedBody["first_name"], "Will");
      expect(jsonParsedBody["last_name"], "McAvoy");
    });

    test('New user request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateNewItemRequest(
          endpointName: "users",
          endpointPrefix: "/",
          objectData: {
            "first_name": "John",
            "last_name": "Doe",
            "email": "will@acn.com"
          });
      expect(request.request.url.toString(), "http://api.com/users?fields=*");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Update Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareUpdateItemRequest(
          endpointName: "articles",
          endpointPrefix: "/items/",
          itemId: "abc-123",
          objectData: {
            "title": "Let's dance",
            "pageCount": 9,
            "creationDate": DateTime(2022, 1, 2, 3, 4, 5)
          },
          fields: "*.*");
      expect(request.request.url.toString(),
          "http://api.com/items/articles/abc-123?fields=*.*");
      expect(request.request.method, "PATCH");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["title"], "Let's dance");
      expect(jsonParsedBody["pageCount"], 9);
      expect(jsonParsedBody["creationDate"], "2022-01-02T03:04:05.000");
    });

    test('Delete Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareDeleteItemRequest(
          endpointName: "articles",
          endpointPrefix: "/items/",
          itemId: "abc-123",
          mustBeAuthenticated: false);
      expect(request.request.url.toString(),
          "http://api.com/items/articles/abc-123");
      expect(request.request.method, "DELETE");
    });

    test('Delete Item ok responses', () {
      final sut = makeAuthenticatedDirectusAPI();

      expect(sut.parseGenericBoolResponse(Response("", 200)), true);
      expect(sut.parseGenericBoolResponse(Response("", 299)), true);
    });

    test('Delete Item denied responses', () {
      final sut = makeAuthenticatedDirectusAPI();

      expect(() => sut.parseGenericBoolResponse(Response("", 300)),
          throwsException);
      expect(() => sut.parseGenericBoolResponse(Response("", 400)),
          throwsException);
    });

    test("Delete multiple items request", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareDeleteMultipleItemRequest(
          endpointName: "articles",
          endpointPrefix: "/items/",
          itemIdList: ["abc-123", "def-456"],
          mustBeAuthenticated: false);
      expect(request.request.url.toString(), "http://api.com/items/articles");
      expect(request.request.method, "DELETE");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      expect(request.request.body, jsonEncode(["abc-123", "def-456"]));
    });
  });

  group('DirectusAPI Users management', () {
    test('Correct initialization', () {
      expect(DirectusAPI("http://api.com").baseURL, "http://api.com");
      expect(DirectusAPI("http://api.com/").baseURL, "http://api.com",
          reason: "Trailing / should be removed from base url");
    });

    test('Login request', () {
      final sut = DirectusAPI("http://api.com");
      final request = sut.prepareLoginRequest("will@acn.com", "mc!avoy");
      expect(request.request.url.toString(), "http://api.com/auth/login");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "mc!avoy");
    });

    test('Login request with OneTimePassword', () {
      final sut = DirectusAPI("http://api.com");
      final request = sut.prepareLoginRequest("will@acn.com", "mc!avoy",
          oneTimePassword: "123456");
      expect(request.request.url.toString(), "http://api.com/auth/login");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "mc!avoy");
      expect(jsonParsedBody["otp"], "123456");
    });

    test('Invite request', () {
      final sut = DirectusAPI("http://api.com");
      final request =
          sut.prepareUserInviteRequest("will@acn.com", "abc-user-role-123");
      expect(request.request.url.toString(), "http://api.com/users/invite");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["role"], "abc-user-role-123");
    });

    test('Successful Login response', () {
      String? savedToken;
      final sut = DirectusAPI("http://api.com",
          saveRefreshTokenCallback: (t) async => savedToken = t);
      expect(sut.hasLoggedInUser, false);
      final response = Response("""
      {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
      """, 200);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.success);
      expect(loginResponse.message, isNull);
      expect(sut.accessToken, "ABCD.1234.ABCD");
      expect(sut.refreshToken, "REFRESH.TOKEN.5678");
      expect(savedToken, "REFRESH.TOKEN.5678",
          reason:
              "We passed a save function for refresh token, it should be used");
      expect(sut.shouldRefreshToken, false);
      expect(sut.hasLoggedInUser, true);
    });

    test('Failed Login response', () {
      final sut = DirectusAPI("http://api.com");
      final response = Response("""
      {"errors":[{"message":"Invalid user credentials.","extensions":{"code":"INVALID_CREDENTIALS"}}]}
      """, 401);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.invalidCredentials);
      expect(loginResponse.message, "Invalid user credentials.\n");
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Login with invalid OneTimePassword response', () {
      final sut = DirectusAPI("http://api.com");
      final response = Response("""
      {"errors":[{"message":"Invalid user OTP.","extensions":{"code":"INVALID_OTP"}}]}
      """, 401);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.invalidOTP);
      expect(loginResponse.message, "Invalid user OTP.\n");
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Error during Login response', () {
      final sut = DirectusAPI("http://api.com");
      final response = Response("""
      {"errors":[{"message":"Special error","extensions":{"code":"SPECIAL_ERROR"}}]}
      """, 500);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.error);
      expect(loginResponse.message, "Special error\n");
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Error during Login response - bad json', () {
      final sut = DirectusAPI("http://api.com");
      final response = Response("""
      {"data":{"weird_json":"ABCD.1234.ABCD","fake_key":900000,"tok_tok":"REFRESH.TOKEN.5678"}}
      """, 200);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.error);
      expect(loginResponse.message, "Unrecognized response");
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Impossible Refresh Token request', () async {
      final sut = DirectusAPI("http://api.com");
      final request = sut.prepareRefreshTokenRequest();
      expect(await request.request, isNull,
          reason: "No refresh token is available");
    });

    test('Valid Refresh Token request', () async {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareRefreshTokenRequest();
      final request = await preparedRequest.request;
      expect(request, isNotNull,
          reason: "User did log in, so refresh should be available");
      expect(request.url.toString(), "http://api.com/auth/refresh");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["refresh_token"], defaultRefreshToken);
    });

    test('Load Refresh Token from backup and prepare request', () async {
      final sut =
          DirectusAPI("http://api.com", loadRefreshTokenCallback: () async {
        return "LOADED.TOKEN.REFRESH";
      });
      final preparedRequest = sut.prepareRefreshTokenRequest();
      final request = await preparedRequest.request;
      expect(request, isNotNull,
          reason:
              "A refresh token is available in the cache, so the request can be made");
      expect(request.url.toString(), "http://api.com/auth/refresh");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["refresh_token"], "LOADED.TOKEN.REFRESH");
    });

    test('Failed load Refresh Token from backup', () async {
      final sut =
          DirectusAPI("http://api.com", loadRefreshTokenCallback: () async {
        return null;
      });
      final preparedRequest = sut.prepareRefreshTokenRequest();
      expect(await preparedRequest.request, isNull,
          reason:
              "No refresh token is available in the cache, so the request cannot be made");
    });

    test('Refresh Token valid response', () {
      String? savedToken;
      final sut = DirectusAPI("http://api.com",
          saveRefreshTokenCallback: (t) async => savedToken = t);
      final pendingRequest =
          Request("GET", Uri.parse("http://api.com/items/stuff"));
      pendingRequest.headers["Authorization"] = "Bearer OLD.ACCESS.TOKEN";
      final refreshResponse = Response("""
      {"data":{"access_token":"NEW.ACCESS.TOKEN","expires":900000,"refresh_token":"NEW.REFRESH.TOKEN"}}
      """, 200);
      final newPendingRequest = sut.parseRefreshTokenResponse(refreshResponse);
      expect(newPendingRequest, isTrue);

      expect(sut.accessToken, "NEW.ACCESS.TOKEN");
      expect(sut.refreshToken, "NEW.REFRESH.TOKEN");
      expect(savedToken, "NEW.REFRESH.TOKEN",
          reason:
              "We passed a save function for refresh token, it should be used");
      expect(sut.shouldRefreshToken, false);
    });

    test('Failed Refresh token response', () {
      final sut = DirectusAPI("http://api.com");
      final pendingRequest =
          Request("GET", Uri.parse("http://api.com/items/stuff"));
      pendingRequest.headers["Authorization"] = "Bearer OLD.ACCESS.TOKEN";
      final response = Response("""
      {"errors":[{"message":"Invalid user credentials.","extensions":{"code":"INVALID_CREDENTIALS"}}]}
      """, 401);
      expect(sut.parseRefreshTokenResponse(response), isFalse);
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Invalidate previous token when refresh fails', () {
      final sut = makeAuthenticatedDirectusAPI();
      expect(sut.accessToken, isNotNull);
      expect(sut.refreshToken, isNotNull);
      final pendingRequest =
          Request("GET", Uri.parse("http://api.com/items/stuff"));
      pendingRequest.headers["Authorization"] = "Bearer OLD.ACCESS.TOKEN";
      final response = Response("""
      {"errors":[{"message":"Invalid user credentials.","extensions":{"code":"INVALID_CREDENTIALS"}}]}
      """, 401);
      expect(sut.parseRefreshTokenResponse(response), isFalse);
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Impossible Logout request', () {
      final sut = DirectusAPI("http://api.com");
      final request = sut.prepareLogoutRequest();
      expect(request, isNull, reason: "Use did not login first");
    });

    test('Valid Logout request', () {
      final sut = makeAuthenticatedDirectusAPI();
      expect(sut.accessToken, isNotNull);
      expect(sut.refreshToken, isNotNull);
      final request = sut.prepareLogoutRequest();
      expect(request, isNotNull,
          reason: "Use did login first, should be able to logout");
      expect(request?.request.url.toString(), "http://api.com/auth/logout");
      expect(request?.request.method, "POST");
      expect(request?.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request?.request.body);
      expect(jsonParsedBody["refresh_token"], defaultRefreshToken);
    });

    test('Parse Valid Logout response', () {
      final sut = makeAuthenticatedDirectusAPI();
      expect(sut.accessToken, isNotNull);
      expect(sut.refreshToken, isNotNull);
      final didLogout = sut.parseLogoutResponse(Response("", 200));
      expect(didLogout, true);
      expect(sut.accessToken, isNull);
      expect(sut.refreshToken, isNull);
      expect(sut.shouldRefreshToken, false);
    });

    test('Get specific user request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetSpecificItemRequest(
          endpointName: "users", itemId: "123", endpointPrefix: "/");
      expect(
          request.request.url.toString(), "http://api.com/users/123?fields=*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get current user request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetCurrentUserRequest();
      expect(
          request.request.url.toString(), "http://api.com/users/me?fields=*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get current user request with fields', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareGetCurrentUserRequest(fields: "*,field1.*,field2.*");
      expect(request.request.url.toString(),
          "http://api.com/users/me?fields=*,field1.*,field2.*");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Get list of users request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest(
          endpointName: "users",
          endpointPrefix: "/",
          filter: PropertyFilter(
              field: "firstName",
              operator: FilterOperator.equals,
              value: "jordan"),
          limit: 10,
          fields: "*.*",
          sortBy: [SortProperty("id", ascending: false)],
          offset: 4);
      expect(request.request.url.toString(),
          "http://api.com/users?fields=*.*&filter=%7B+%22firstName%22%3A+%7B+%22_eq%22%3A+%22jordan%22+%7D%7D&limit=10&sort=-id&offset=4");
      expect(request.request.method, "GET");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });

    test('Update User request with modification', () {
      final sut = makeAuthenticatedDirectusAPI();
      final user = DirectusUser({
        "id": "123-abc-456",
        "email": "will@acn.com",
        "first_name": "Will",
        "score": 23
      });
      user.firstname = "Will 2";
      user.setValue(DateTime(2022, 1, 2, 3, 4, 5), forKey: "birthDate");
      final request = sut.prepareUpdateItemRequest(
          endpointName: "users",
          endpointPrefix: "/",
          objectData: user.updatedProperties,
          itemId: user.id!,
          fields: "*.*");

      expect(request.request.url.toString(),
          "http://api.com/users/123-abc-456?fields=*.*");
      expect(request.request.method, "PATCH");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.request.body) as Map;
      expect(jsonParsedBody["first_name"], "Will 2");
      expect(jsonParsedBody["birthDate"], "2022-01-02T03:04:05.000");
      expect(jsonParsedBody.containsKey("email"), false,
          reason: "Only modified properties should be sent");
      expect(jsonParsedBody.containsKey("id"), false,
          reason: "Only modified properties should be sent");
      expect(jsonParsedBody.containsKey("score"), false,
          reason: "Only modified properties should be sent");
    });

    test('Update User request with no modification', () {
      final sut = makeAuthenticatedDirectusAPI();
      final user = DirectusUser({
        "id": "123-abc-456",
        "email": "will@acn.com",
        "first_name": "Will",
        "score": 23
      });
      final request = sut.prepareUpdateItemRequest(
          endpointName: "users",
          endpointPrefix: "/",
          objectData: user.updatedProperties,
          itemId: user.id!,
          fields: "*.*");
      expect(request.request.url.toString(),
          "http://api.com/users/123-abc-456?fields=*.*");
      expect(request.request.method, "PATCH");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.request.body) as Map;
      expect(jsonParsedBody, isEmpty);
    });

    test('Request user password reset', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordResetRequest(email: "will@acn.com");
      expect(request.request.url.toString(),
          "http://api.com/auth/password/request");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body) as Map;
      expect(jsonParsedBody["email"], "will@acn.com");
    });

    test('Request user password reset with reset url', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordResetRequest(
          email: "will@acn.com", resetUrl: "https://my-custom-reset-url.com");
      expect(request.request.url.toString(),
          "http://api.com/auth/password/request");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body) as Map;
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["reset_url"], "https://my-custom-reset-url.com");
    });

    test('Request user password change', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordChangeRequest(
          newPassword: "new-password", token: "token-abc");
      expect(
          request.request.url.toString(), "http://api.com/auth/password/reset");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.request.body) as Map;
      expect(jsonParsedBody["password"], "new-password");
      expect(jsonParsedBody["token"], "token-abc");
    });

    test('Delete User request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareDeleteItemRequest(
          endpointName: "users",
          endpointPrefix: "/",
          itemId: "123-abc-456",
          mustBeAuthenticated: true);

      expect(
          request.request.url.toString(), "http://api.com/users/123-abc-456");
      expect(request.request.method, "DELETE");
      expect(request.request.headers["Authorization"],
          "Bearer $defaultAccessToken");
    });
  });

  group("DirectusAPI : Files", () {
    test("prepareNewFileUploadRequest", () {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], filename: "file.txt");
      final request = preparedRequest.request;
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files.length, 1);
      final uploadedFileData = multipartRequest.files[0];
      expect(uploadedFileData.filename, "file.txt");
    });

    test("contentType", () {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], contentType: "image/jpg", filename: "file.txt");
      final request = preparedRequest.request;
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files[0].contentType.mimeType, "image/jpg");
    });

    test("wildcard contentType", () {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], contentType: "image/*", filename: "file.txt");
      final request = preparedRequest.request;
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files[0].contentType.mimeType, "image/*");
    });

    test("Title", () {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], title: "File title", filename: "file.txt");
      final request = preparedRequest.request;
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.fields["title"], "File title");
    });

    test("Folder", () {
      final sut = makeAuthenticatedDirectusAPI();
      final preparedRequest = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], folder: "Folder", filename: "file.txt");
      final request = preparedRequest.request;
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.fields["folder"], "Folder");
    });

    test("File import from URL", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileImportRequest(
          url: "https://www.purplegiraffe.fr/image.png", title: "File title");

      expect(request.request.url.toString(), "http://api.com/files/import");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final json = jsonDecode(request.request.body);
      expect(json["url"], "https://www.purplegiraffe.fr/image.png");
      expect(json["data"]["title"], "File title");
    });

    test("File import from URL with folder", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileImportRequest(
          url: "https://www.purplegiraffe.fr/image.png",
          title: "File title",
          folder: "Folder");

      expect(request.request.url.toString(), "http://api.com/files/import");
      expect(request.request.method, "POST");
      expect(request.request.headers["Content-Type"],
          "application/json; charset=utf-8");
      final json = jsonDecode(request.request.body);
      expect(json["url"], "https://www.purplegiraffe.fr/image.png");
      expect(json["data"]["title"], "File title");
      expect(json["data"]["folder"], "Folder");
    });

    test("File delete request", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileDeleteRequest(fileId: "a");

      expect(request.request.url.toString(), "http://api.com/files/a");
      expect(request.request.method, "DELETE");
    });
  });
}
