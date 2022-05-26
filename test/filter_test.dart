import 'package:directus_api_manager/src/filter.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  test('PropertyFilter equals', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.equals, value: "Hello World!");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_eq": "Hello World!" }}');
  });
  test('PropertyFilter isNull', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.isNull, value: null);
    final json = sut.asJSON;
    expect(json, '{ "title": { "_null": null }}');
  });

  test('PropertyFilter contains', () {
    final sut = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final json = sut.asJSON;
    expect(json, '{ "title": { "_contains": "Hello" }}');
  });

  test('PropertyFilter between', () {
    final sut = PropertyFilter(
        field: "score", operator: FilterOperator.between, value: [10, 100]);
    final json = sut.asJSON;
    expect(json, '{ "score": { "_between": [10, 100] }}');
  });

  test('PropertyFilter between system variables', () {
    final sut = PropertyFilter(
        field: "start_date",
        operator: FilterOperator.between,
        value: ["\$NOW", "\$NOW(+2 weeks)"]);
    final json = sut.asJSON;
    expect(
        json, '{ "start_date": { "_between": ["\$NOW", "\$NOW(+2 weeks)"] }}');
  });

  test('LogicalFilter and', () {
    final a1 = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final a2 = PropertyFilter(
        field: "description", operator: FilterOperator.equals, value: "world");
    final sut = LogicalOperatorFilter(
        operator: LogicalOperator.and, children: [a1, a2]);
    final json = sut.asJSON;
    expect(json,
        '{ "_and": [ { "title": { "_contains": "Hello" }} , { "description": { "_eq": "world" }} ] }');
  });

  test('LogicalFilter or', () {
    final a1 = PropertyFilter(
        field: "title", operator: FilterOperator.contains, value: "Hello");
    final a2 = PropertyFilter(
        field: "description", operator: FilterOperator.equals, value: "world");
    final sut =
        LogicalOperatorFilter(operator: LogicalOperator.or, children: [a1, a2]);
    final json = sut.asJSON;
    expect(json,
        '{ "_or": [ { "title": { "_contains": "Hello" }} , { "description": { "_eq": "world" }} ] }');
  });

  test('RelationFilter _eq', () {
    final sut = RelationFilter(
        propertyName: "users",
        linkedObjectFilter: PropertyFilter(
            field: "id", operator: FilterOperator.equals, value: "23"));
    final json = sut.asJSON;
    expect(json, '{ "users": { "id": { "_eq": "23" }}}');
  });
}
