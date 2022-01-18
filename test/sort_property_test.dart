import 'package:directus_api_manager/src/sort_property.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group("SortProperty", () {
    test("ascending by default", () {
      final sut = SortProperty("score");
      expect(sut.ascending, true);
    });
    test("toString ascending", () {
      final sut = SortProperty("score", ascending: true);
      expect(sut.toString(), "score");
    });
    test("toString descending", () {
      final sut = SortProperty("score", ascending: false);
      expect(sut.toString(), "-score");
    });
  });
}
