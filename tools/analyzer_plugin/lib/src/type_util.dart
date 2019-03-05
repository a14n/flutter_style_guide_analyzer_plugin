import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

final collectionInterfaces = <InterfaceTypeDefinition>[
  new InterfaceTypeDefinition('List', 'dart.core'),
  new InterfaceTypeDefinition('Map', 'dart.core'),
  new InterfaceTypeDefinition('LinkedHashMap', 'dart.collection'),
  new InterfaceTypeDefinition('Set', 'dart.core'),
  new InterfaceTypeDefinition('LinkedHashSet', 'dart.collection'),
];

bool isWidget(DartType type) => implementsInterface(type, 'Widget', '');

bool isWidgetOrCollectionOfWidget(DartType type) {
  if (isWidget(type)) {
    return true;
  }
  if (type is ParameterizedType &&
      implementsAnyInterface(type, collectionInterfaces)) {
    return type.typeParameters.length == 1 &&
        isWidget(type.typeArguments.first);
  }
  return false;
}

bool implementsAnyInterface(
    DartType type, Iterable<InterfaceTypeDefinition> definitions) {
  if (type is! InterfaceType) {
    return false;
  }
  bool predicate(InterfaceType i) =>
      definitions.any((d) => isInterface(i, d.name, d.library));
  ClassElement element = type.element;
  return predicate(type) ||
      !element.isSynthetic && element.allSupertypes.any(predicate);
}

bool implementsInterface(DartType type, String interface, String library) {
  if (type is! InterfaceType) {
    return false;
  }
  bool predicate(InterfaceType i) => isInterface(i, interface, library);
  ClassElement element = type.element;
  return predicate(type) ||
      !element.isSynthetic && element.allSupertypes.any(predicate);
}

bool isInterface(InterfaceType type, String interface, String library) =>
    type.name == interface && type.element.library.name == library;

class InterfaceTypeDefinition {
  final String name;
  final String library;

  InterfaceTypeDefinition(this.name, this.library);

  @override
  int get hashCode => name.hashCode ^ library.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InterfaceTypeDefinition &&
        name == other.name &&
        library == other.library;
  }
}
