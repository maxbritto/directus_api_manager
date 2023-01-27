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

  group("DirectusAPI Data Management", () {
    test('Get list of items request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareGetListOfItemsRequest("article", fields: "*.*");
      expect(request.url.toString(), "http://api.com/items/article?fields=*.*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"));
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with sort and filter request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article",
          sortBy: [
            SortProperty("score", ascending: false),
            SortProperty("level")
          ],
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"));
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&sort=-score,level');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with sort request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article", sortBy: [
        SortProperty("score", ascending: false),
        SortProperty("level")
      ]);
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&sort=-score,level');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article", limit: 10);
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&limit=10');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter and limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"),
          limit: 10);
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&limit=10');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with offset request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article", offset: 10);
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&offset=10');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get list of items with filter, sort and limit request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article",
          filter: PropertyFilter(
              field: "title", operator: FilterOperator.equals, value: "A"),
          sortBy: [
            SortProperty("score", ascending: false),
            SortProperty("level")
          ],
          limit: 10);
      expect(request.url.toString(),
          'http://api.com/items/article?fields=*&filter=%7B+%22title%22%3A+%7B+%22_eq%22%3A+%22A%22+%7D%7D&limit=10&sort=-score,level');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });
    test('Get list of items with filter that includes special characters', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetListOfItemsRequest("article",
          filter: PropertyFilter(
              field: "date",
              operator: FilterOperator.between,
              value: [r"$NOW", r"$NOW(+2 weeks)"]));
      expect(request.url.toString(),
          r'http://api.com/items/article?fields=*&filter=%7B+%22date%22%3A+%7B+%22_between%22%3A+%5B%22%24NOW%22%2C+%22%24NOW%28%2B2+weeks%29%22%5D+%7D%7D');
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get specific item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetSpecificItemRequest("article", "123");
      expect(
          request.url.toString(), "http://api.com/items/article/123?fields=*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get specific item request with deep fields', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareGetSpecificItemRequest("article", "123", fields: "*.*");
      expect(request.url.toString(),
          "http://api.com/items/article/123?fields=*.*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('New Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateNewItemRequest(
          "articles",
          {
            "title": "Let's dance",
            "pageCount": 10,
            "creationDate": DateTime(2022, 1, 2, 3, 4, 5)
          },
          fields: "*.*");
      expect(
          request.url.toString(), "http://api.com/items/articles?fields=*.*");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["title"], "Let's dance");
      expect(jsonParsedBody["pageCount"], 10);
      expect(jsonParsedBody["creationDate"], "2022-01-02T03:04:05.000");
    });

    test('Update Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareUpdateItemRequest(
          "articles",
          "abc-123",
          {
            "title": "Let's dance",
            "pageCount": 9,
            "creationDate": DateTime(2022, 1, 2, 3, 4, 5)
          },
          fields: "*.*");
      expect(request.url.toString(),
          "http://api.com/items/articles/abc-123?fields=*.*");
      expect(request.method, "PATCH");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["title"], "Let's dance");
      expect(jsonParsedBody["pageCount"], 9);
      expect(jsonParsedBody["creationDate"], "2022-01-02T03:04:05.000");
    });

    test('Delete Item request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareDeleteItemRequest("articles", "abc-123", false);
      expect(request.url.toString(), "http://api.com/items/articles/abc-123");
      expect(request.method, "DELETE");
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
      expect(request.url.toString(), "http://api.com/auth/login");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "mc!avoy");
    });

    test('Invite request', () {
      final sut = DirectusAPI("http://api.com");
      final request =
          sut.prepareUserInviteRequest("will@acn.com", "abc-user-role-123");
      expect(request.url.toString(), "http://api.com/users/invite");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["role"], "abc-user-role-123");
    });

    test('Successful Login response', () {
      String? savedToken;
      final sut = DirectusAPI("http://api.com",
          saveRefreshTokenCallback: (t) async => savedToken = t);
      final response = Response("""
      {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
      """, 200);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.success);
      expect(sut.accessToken, "ABCD.1234.ABCD");
      expect(sut.refreshToken, "REFRESH.TOKEN.5678");
      expect(savedToken, "REFRESH.TOKEN.5678",
          reason:
              "We passed a save function for refresh token, it should be used");
      expect(sut.shouldRefreshToken, false);
    });

    test('Failed Login response', () {
      final sut = DirectusAPI("http://api.com");
      final response = Response("""
      {"errors":[{"message":"Invalid user credentials.","extensions":{"code":"INVALID_CREDENTIALS"}}]}
      """, 401);
      final loginResponse = sut.parseLoginResponse(response);
      expect(loginResponse.type, DirectusLoginResultType.invalidCredentials);
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

    test('Error during Login response', () {
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
      final request = await sut.prepareRefreshTokenRequest();
      expect(request, isNull, reason: "No refresh token is available");
    });
    test('Valid Refresh Token request', () async {
      final sut = makeAuthenticatedDirectusAPI();
      final request = await sut.prepareRefreshTokenRequest();
      expect(request, isNotNull,
          reason: "User did log in, so refresh should be available");
      expect(request?.url.toString(), "http://api.com/auth/refresh");
      expect(request?.method, "POST");
      expect(
          request?.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request!.body);
      expect(jsonParsedBody["refresh_token"], defaultRefreshToken);
    });

    test('Load Refresh Token from backup and prepare request', () async {
      final sut =
          DirectusAPI("http://api.com", loadRefreshTokenCallback: () async {
        return "LOADED.TOKEN.REFRESH";
      });
      final request = await sut.prepareRefreshTokenRequest();
      expect(request, isNotNull,
          reason:
              "A refresh token is available in the cache, so the request can be made");
      expect(request?.url.toString(), "http://api.com/auth/refresh");
      expect(request?.method, "POST");
      expect(
          request?.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request!.body);
      expect(jsonParsedBody["refresh_token"], "LOADED.TOKEN.REFRESH");
    });

    test('Failed load Refresh Token from backup', () async {
      final sut =
          DirectusAPI("http://api.com", loadRefreshTokenCallback: () async {
        return null;
      });
      final request = await sut.prepareRefreshTokenRequest();
      expect(request, isNull,
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
      expect(request?.url.toString(), "http://api.com/auth/logout");
      expect(request?.method, "POST");
      expect(
          request?.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request!.body);
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
      final request =
          sut.prepareGetSpecificUserRequest("abc-123", fields: "*.*");
      expect(request.url.toString(), "http://api.com/users/abc-123?fields=*.*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get specific user request with fields', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareGetSpecificUserRequest("abc-123", fields: "first_name");
      expect(request.url.toString(),
          "http://api.com/users/abc-123?fields=first_name");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get current user request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetCurrentUserRequest();
      expect(request.url.toString(), "http://api.com/users/me?fields=*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Get current user request with fields', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request =
          sut.prepareGetCurrentUserRequest(fields: "*,field1.*,field2.*");
      expect(request.url.toString(),
          "http://api.com/users/me?fields=*,field1.*,field2.*");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Parse user response', () {
      final responseBody = """
      {"data":{
      	"id": "0bc7b36a-9ba9-4ce0-83f0-0a526f354e07",
        "first_name": "Admin",
        "last_name": "User",
        "email": "admin@example.com",
        "password": "**********",
        "location": "New York City",
        "title": "CTO",
        "description": null,
        "tags": null,
        "avatar": null,
        "language": "en-US",
        "theme": "auto",
        "tfa_secret": null,
        "status": "active",
        "role": "653925a9-970e-487a-bfc0-ab6c96affcdc",
        "token": null,
        "last_access": "2021-02-05T10:18:13-05:00",
        "last_page": "/settings/roles/653925a9-970e-487a-bfc0-ab6c96affcdc"
      }}
      """;
      final sut = DirectusAPI("http://api.com");
      final parsedUser = sut.parseUserResponse(Response(responseBody, 200));
      expect(parsedUser.id, "0bc7b36a-9ba9-4ce0-83f0-0a526f354e07");
      expect(parsedUser.email, "admin@example.com");
      expect(parsedUser.firstname, "Admin");
      expect(parsedUser.lastname, "User");
      expect(parsedUser.getValue(forKey: "title"), "CTO");
    });

    test('Get list of users request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareGetUserListRequest(
          filter: PropertyFilter(
              field: "firstName",
              operator: FilterOperator.equals,
              value: "jordan"),
          limit: 10,
          fields: "*.*",
          sortBy: [SortProperty("id", ascending: false)],
          offset: 4);
      expect(request.url.toString(),
          "http://api.com/users?fields=*.*&filter=%7B+%22firstName%22%3A+%7B+%22_eq%22%3A+%22jordan%22+%7D%7D&limit=10&sort=-id&offset=4");
      expect(request.method, "GET");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
    });

    test('Parse user list response', () {
      final responseBody = """
      {"data":[{
      	"id": "00000001-9ba9-4ce0-83f0-0a526f354e07",
        "first_name": "firstname1",
        "last_name": "lastname1",
        "email": "email1@example.com",
        "password": "**********",
        "location": "New York City",
        "title": "CTO",
        "description": null,
        "tags": null,
        "avatar": null,
        "language": "en-US",
        "theme": "auto",
        "tfa_secret": null,
        "status": "active",
        "role": "653925a9-970e-487a-bfc0-ab6c96affcdc",
        "token": null,
        "last_access": "2021-02-05T10:18:13-05:00",
        "last_page": "/settings/roles/653925a9-970e-487a-bfc0-ab6c96affcdc"
      },
      {
      	"id": "00000002-9ba9-4ce0-83f0-0a526f354e07",
        "first_name": "firstname2",
        "last_name": "lastname2",
        "email": "email2@example.com",
        "password": "**********",
        "location": "New York City",
        "title": "CTO",
        "description": null,
        "tags": null,
        "avatar": null,
        "language": "en-US",
        "theme": "auto",
        "tfa_secret": null,
        "status": "active",
        "role": "653925a9-970e-487a-bfc0-ab6c96affcdc",
        "token": null,
        "last_access": "2021-02-05T10:18:13-05:00",
        "last_page": "/settings/roles/653925a9-970e-487a-bfc0-ab6c96affcdc"
      }
      ]}
      """;
      final sut = DirectusAPI("http://api.com");
      final parsedUserList =
          sut.parseUserListResponse(Response(responseBody, 200));
      expect(parsedUserList.length, 2);
      expect(parsedUserList.elementAt(0).id,
          "00000001-9ba9-4ce0-83f0-0a526f354e07");
      expect(parsedUserList.elementAt(0).email, "email1@example.com");
      expect(parsedUserList.elementAt(0).firstname, "firstname1");
      expect(parsedUserList.elementAt(0).lastname, "lastname1");

      expect(parsedUserList.elementAt(1).id,
          "00000002-9ba9-4ce0-83f0-0a526f354e07");
      expect(parsedUserList.elementAt(1).email, "email2@example.com");
      expect(parsedUserList.elementAt(1).firstname, "firstname2");
      expect(parsedUserList.elementAt(1).lastname, "lastname2");
    });

    test('Create User request (minimum data)', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateUserRequest(
          email: "will@acn.com", password: "will!acn");
      expect(request.url.toString(), "http://api.com/users");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "will!acn");
    });

    test('Create User request (some extra data)', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateUserRequest(
          email: "will@acn.com",
          password: "will!acn",
          firstname: "Will",
          lastname: "McAvoy",
          roleUUID: "001-abcd-1234-cfvg");
      expect(request.url.toString(), "http://api.com/users");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "will!acn");
      expect(jsonParsedBody["first_name"], "Will");
      expect(jsonParsedBody["last_name"], "McAvoy");
      expect(jsonParsedBody["role"], "001-abcd-1234-cfvg");
    });

    test('Create User request (many extra data)', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareCreateUserRequest(
          email: "will@acn.com",
          password: "will!acn",
          firstname: "Will",
          lastname: "McAvoy",
          roleUUID: "001-abcd-1234-cfvg",
          otherProperties: {
            "description": "Main achor",
            "custom_property": "custom_value",
            "score": 23,
            "birthDate": DateTime(2022, 1, 2, 3, 4, 5)
          });
      expect(request.url.toString(), "http://api.com/users");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      final jsonParsedBody = jsonDecode(request.body);
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["password"], "will!acn");
      expect(jsonParsedBody["first_name"], "Will");
      expect(jsonParsedBody["last_name"], "McAvoy");
      expect(jsonParsedBody["role"], "001-abcd-1234-cfvg");
      expect(jsonParsedBody["description"], "Main achor");
      expect(jsonParsedBody["custom_property"], "custom_value");
      expect(jsonParsedBody["score"], 23);
      expect(jsonParsedBody["birthDate"], "2022-01-02T03:04:05.000");
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
      final request = sut.prepareUpdateUserRequest(user);
      if (request != null) {
        expect(request.url.toString(), "http://api.com/users/123-abc-456");
        expect(request.method, "PATCH");
        expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
        final jsonParsedBody = jsonDecode(request.body) as Map;
        expect(jsonParsedBody["first_name"], "Will 2");
        expect(jsonParsedBody["birthDate"], "2022-01-02T03:04:05.000");
        expect(jsonParsedBody.containsKey("email"), false,
            reason: "Only modified properties should be sent");
        expect(jsonParsedBody.containsKey("id"), false,
            reason: "Only modified properties should be sent");
        expect(jsonParsedBody.containsKey("score"), false,
            reason: "Only modified properties should be sent");
      } else {
        expect(request, request is Request, reason: "Request must not be null");
      }
    });
    test('Update User request with no modification', () {
      final sut = makeAuthenticatedDirectusAPI();
      final user = DirectusUser({
        "id": "123-abc-456",
        "email": "will@acn.com",
        "first_name": "Will",
        "score": 23
      });
      final request = sut.prepareUpdateUserRequest(user);
      if (request != null) {
        expect(request.url.toString(), "http://api.com/users/123-abc-456");
        expect(request.method, "PATCH");
        expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
        final jsonParsedBody = jsonDecode(request.body) as Map;
        expect(jsonParsedBody, isEmpty);
      } else {
        expect(request, request is Request, reason: "Request must not be null");
      }
    });
    test('Request user password reset', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordResetRequest(email: "will@acn.com");
      expect(request.url.toString(), "http://api.com/auth/password/request");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body) as Map;
      expect(jsonParsedBody["email"], "will@acn.com");
    });
    test('Request user password reset with reset url', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordResetRequest(
          email: "will@acn.com", resetUrl: "https://my-custom-reset-url.com");
      expect(request.url.toString(), "http://api.com/auth/password/request");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body) as Map;
      expect(jsonParsedBody["email"], "will@acn.com");
      expect(jsonParsedBody["reset_url"], "https://my-custom-reset-url.com");
    });
    test('Request user password change', () {
      final sut = makeAuthenticatedDirectusAPI();

      final request = sut.preparePasswordChangeRequest(
          newPassword: "new-password", token: "token-abc");
      expect(request.url.toString(), "http://api.com/auth/password/reset");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final jsonParsedBody = jsonDecode(request.body) as Map;
      expect(jsonParsedBody["password"], "new-password");
      expect(jsonParsedBody["token"], "token-abc");
    });

    test('Delete User request', () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareDeleteUserRequest(
          DirectusUser({
            "id": "123-abc-456",
            "email": "will@acn.com",
            "first_name": "Will",
            "score": 23
          }),
          true);
      if (request != null) {
        expect(request.url.toString(), "http://api.com/users/123-abc-456");
        expect(request.method, "DELETE");
        expect(request.headers["Authorization"], "Bearer $defaultAccessToken");
      } else {
        expect(request, request is Request);
      }
    });

    test('Delete User ok responses', () {
      final sut = makeAuthenticatedDirectusAPI();

      expect(sut.parseDeleteUserResponse(Response("", 200)), true);
      expect(sut.parseDeleteUserResponse(Response("", 299)), true);
    });
    test('Delete User denied responses', () {
      final sut = makeAuthenticatedDirectusAPI();

      expect(() => sut.parseDeleteUserResponse(Response("", 300)),
          throwsException);
      expect(() => sut.parseDeleteUserResponse(Response("", 400)),
          throwsException);
    });
  });

  group("DirectusAPI : Files", () {
    test("prepareNewFileUploadRequest", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], filename: "file.txt");
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files.length, 1);
      final uploadedFileData = multipartRequest.files[0];
      expect(uploadedFileData.filename, "file.txt");
    });
    test("contentType", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], contentType: "image/jpg", filename: "file.txt");
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files[0].contentType.mimeType, "image/jpg");
    });
    test("wildcard contentType", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], contentType: "image/*", filename: "file.txt");
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.files[0].contentType.mimeType, "image/*");
    });
    test("Title", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], title: "File title", filename: "file.txt");
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.fields["title"], "File title");
    });
    test("Folder", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareNewFileUploadRequest(
          fileBytes: [1, 2, 3], folder: "Folder", filename: "file.txt");
      expect(request, isA<MultipartRequest>());
      final multipartRequest = request as MultipartRequest;
      expect(multipartRequest.fields["folder"], "Folder");
    });
    test("File import from URL", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileImportRequest(
          url: "https://www.purplegiraffe.fr/image.png", title: "File title");

      expect(request.url.toString(), "http://api.com/files/import");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final json = jsonDecode(request.body);
      expect(json["url"], "https://www.purplegiraffe.fr/image.png");
      expect(json["data"]["title"], "File title");
    });

    test("File import from URL with folder", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileImportRequest(
          url: "https://www.purplegiraffe.fr/image.png",
          title: "File title",
          folder: "Folder");

      expect(request.url.toString(), "http://api.com/files/import");
      expect(request.method, "POST");
      expect(
          request.headers["Content-Type"], "application/json; charset=utf-8");
      final json = jsonDecode(request.body);
      expect(json["url"], "https://www.purplegiraffe.fr/image.png");
      expect(json["data"]["title"], "File title");
      expect(json["data"]["folder"], "Folder");
    });

    test("File delete request", () {
      final sut = makeAuthenticatedDirectusAPI();
      final request = sut.prepareFileDeleteRequest(fileId: "a");

      expect(request.url.toString(), "http://api.com/files/a");
      expect(request.method, "DELETE");
    });
  });
}
