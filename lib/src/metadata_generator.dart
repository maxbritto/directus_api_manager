import 'package:reflectable/reflectable.dart';

import 'annotations.dart';

class MetadataGenerator {
  final directusCollection = const DirectusCollection();
  final Map<String, ClassMirror> classes = <String, ClassMirror>{};

  MetadataGenerator() {
    for (final classMirror in directusCollection.annotatedClasses) {
      classes[classMirror.reflectedType.toString()] = classMirror;
    }
  }

  ClassMirror getClassMirrorForType(Type type) {
    final classMirror = classes[type.toString()];
    if (classMirror == null) {
      throw Exception(
          "No class mirror found for type $type. Please add the @DirectusCollection annotation to the class");
    }
    return classMirror;
  }
}
