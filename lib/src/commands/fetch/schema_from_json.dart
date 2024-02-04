import 'package:leto_schema/leto_schema.dart';
import 'package:leto_schema/utilities.dart';

Map<String, GraphQLNamedType> typeMap = {};

GraphQLSchema buildClientSchema(
  Map<String, dynamic> introspection,
) {
  List.from(introspection['__schema']['types'])
      .where((element) => element['kind'] != 'NON_NULL')
      .where((element) => element['kind'] != 'LIST')
      .forEach(
    (typeIntrospection) {
      final data = Map<String, dynamic>.from(typeIntrospection);
      if (data['kind'] == 'NON_NULL' || data['kind'] == 'LIST') {
        final newType = buildType(data['ofType']);
        typeMap[newType.name] = newType;
      } else {
        final newType = buildType(data);
        typeMap[newType.name] = newType;
      }
    },
  );

  final specifiedScalarTypes = [
    graphQLString,
    graphQLBoolean,
    graphQLInt,
    graphQLFloat,
    graphQLBoolean,
    graphQLId,
  ];
  final introspectionTypes = [];

  for (var stdType in [...specifiedScalarTypes, ...introspectionTypes]) {
    if (typeMap.containsKey(stdType.name)) {
      typeMap[stdType.name] = stdType;
    }
  }

  var queryType = introspection['__schema']['queryType'] != null
      ? getObjectType(introspection['__schema']['queryType'])
      : null;

  var mutationType = introspection['__schema']['mutationType'] != null
      ? getObjectType(introspection['__schema']['mutationType'])
      : null;

  var subscriptionType = introspection['__schema']['subscriptionType'] != null
      ? getObjectType(introspection['__schema']['subscriptionType'])
      : null;

  var directives = introspection['__schema']['directives'] != null
      ? List.of(introspection['__schema']['directives'])
          .map((e) => Map<String, dynamic>.from(e))
          .map(buildDirective)
          .toList()
      : <GraphQLDirective>[];

  final data = <GraphQLType>[
    if (queryType != null) queryType,
    if (mutationType != null) mutationType,
    if (subscriptionType != null) subscriptionType,
  ];

  final allTypes = CollectTypes(data).traversedTypes;
  final typeNameRegExp = RegExp(r'^[_a-zA-Z][_a-zA-Z0-9]*$');

  for (final type in allTypes) {
    final name = type.name;
    if (name.isEmpty) {
      throw Exception('Unnamed type : $type');
    } else if ((!typeNameRegExp.hasMatch(name) || name.startsWith('__')) &&
        !isIntrospectionType(type)) {
      throw Exception('Invalid type : $type');
    }
    final prev = typeMap[name];
    if (prev != null) {
      typeMap.remove(name);
    }
  }

  return GraphQLSchema(
    description: introspection['__schema']['description'],
    queryType: queryType,
    mutationType: mutationType,
    subscriptionType: subscriptionType,
    otherTypes: typeMap.values.toList(),
    directives: directives,
  );
}

GraphQLDirective buildDirective(Map<String, dynamic> directiveIntrospection) {
  return GraphQLDirective(
    name: directiveIntrospection['name'],
    description: directiveIntrospection['description'],
    locations: (directiveIntrospection['locations'] as List).map((location) {
      return DirectiveLocation.values.byName(location);
    }).toList(),
  );
}

GraphQLType getType(Map<String, dynamic> typeRef) {
  if (typeRef['kind'] == 'LIST') {
    var itemRef = typeRef['ofType'];
    if (itemRef == null) {
      throw ArgumentError('Decorated type deeper than introspection query.');
    }
    return listOf(getType(itemRef));
  }
  if (typeRef['kind'] == 'NON_NULL') {
    var nullableRef = typeRef['ofType'];
    if (nullableRef == null) {
      throw ArgumentError('Decorated type deeper than introspection query.');
    }
    var nullableType = getType(nullableRef);
    return nullableType.nonNull();
  }
  return getNamedType(typeRef);
}

GraphQLNamedType getNamedType(Map<String, dynamic> typeRef) {
  var typeName = typeRef['name'];
  typeName ??= getNamedType(typeRef['ofType']).name;

  var type = typeMap[typeName];
  if (type == null) {
    type = buildType(typeRef);
    typeMap[type.name] = type;
  }

  return type;
}

GraphQLObjectType getObjectType(Map<String, dynamic> typeRef) {
  return getType(typeRef) as GraphQLObjectType;
}

GraphQLObjectType getInterfaceType(Map<String, dynamic> typeRef) {
  return getType(typeRef) as GraphQLObjectType;
}

GraphQLNamedType buildType(Map<String, dynamic> type) {
  if (type['name'] != null && type['kind'] != null) {
    switch (type['kind']) {
      case 'SCALAR':
        return buildScalarDef(type);
      case 'OBJECT':
        return buildObjectDef(type);
      case 'INTERFACE':
        return buildInterfaceDef(type);
      case 'UNION':
        return buildUnionDef(type);
      case 'ENUM':
        return buildEnumDef(type);
      case 'INPUT_OBJECT':
        return buildInputObjectDef(type);
    }
  }
  var typeStr = type.toString();
  throw ArgumentError(
    'Invalid or incomplete introspection result. Ensure that a full introspection query is used in order to build a client schema: $typeStr.',
  );
}

GraphQLScalarType buildScalarDef(Map<String, dynamic> scalarIntrospection) {
  return GraphQLScalarTypeValue(
    name: scalarIntrospection['name'],
    description: scalarIntrospection['description'],
    specifiedByURL: scalarIntrospection['specifiedByURL'],
    serialize: (value) => value,
    deserialize: (serdeCtx, serialized) => serialized,
    validate: (key, input) => ValidationResult.ok(input),
  );
}

List<GraphQLObjectType> buildImplementationsList(
  Map<String, dynamic> implementingIntrospection,
) {
  if (implementingIntrospection['interfaces'] == null) {
    return [];
  }

  return List.of(implementingIntrospection['interfaces'])
      .map((e) => Map<String, dynamic>.from(e))
      .map(getInterfaceType)
      .toList();
}

List<GraphQLObjectField> buildFieldDefMap(
  Map<String, dynamic> implementingIntrospection,
) {
  if (implementingIntrospection['fields'] == null) {
    return [];
  }

  return List.of(implementingIntrospection['fields'])
      .map((e) => Map<String, dynamic>.from(e))
      .map((value) {
    return GraphQLObjectField(
      value['name'],
      getNamedType(value['type']),
    );
  }).toList();
}

List<GraphQLFieldInput> buildFieldInputDefMap(
  Map<String, dynamic> implementingIntrospection,
) {
  if (implementingIntrospection['inputFields'] == null) {
    return [];
  }

  return List.of(implementingIntrospection['inputFields'])
      .map((e) => Map<String, dynamic>.from(e))
      .map((value) {
    return GraphQLFieldInput(
      value['name'],
      getNamedType(value['type']),
    );
  }).toList();
}

GraphQLObjectType buildObjectDef(Map<String, dynamic> objectIntrospection) {
  return GraphQLObjectType(
    objectIntrospection['name'],
    description: objectIntrospection['description'],
    interfaces: buildImplementationsList(objectIntrospection),
    fields: buildFieldDefMap(objectIntrospection),
  );
}

GraphQLInputObjectType buildInputObjectDef(
    Map<String, dynamic> objectIntrospection) {
  return GraphQLInputObjectType(
    objectIntrospection['name'],
    description: objectIntrospection['description'],
    fields: buildFieldInputDefMap(objectIntrospection),
  );
}

GraphQLObjectType buildInterfaceDef(
  Map<String, dynamic> interfaceIntrospection,
) {
  return GraphQLObjectType(
    interfaceIntrospection['name'],
    description: interfaceIntrospection['description'],
    isInterface: true,
    interfaces: buildImplementationsList(interfaceIntrospection),
    fields: buildFieldDefMap(interfaceIntrospection),
  );
}

GraphQLUnionType buildUnionDef(Map<String, dynamic> unionIntrospection) {
  if (unionIntrospection['possibleTypes'] == null) {
    var unionIntrospectionStr = unionIntrospection.toString();
    throw ArgumentError(
      'Introspection result missing possibleTypes: $unionIntrospectionStr.',
    );
  }
  return GraphQLUnionType(
    unionIntrospection['name'],
    List.of(unionIntrospection['possibleTypes'])
        .map((e) => Map<String, dynamic>.from(e))
        .map(getObjectType)
        .toList(),
    description: unionIntrospection['description'],
  );
}

GraphQLEnumType buildEnumDef(Map<String, dynamic> enumIntrospection) {
  // if (enumIntrospection['enumValues'] == null) {
  //   var enumIntrospectionStr = enumIntrospection.toString();
  //   throw ArgumentError(
  //     'Introspection result missing enumValues: $enumIntrospectionStr.',
  //   );
  // }
  return GraphQLEnumType(
    enumIntrospection['name'],
    enumIntrospection['enumValues'] == null
        ? []
        : List.from(enumIntrospection['enumValues']).map((value) {
            return GraphQLEnumValue(
              value['name'],
              value['name'],
              description: value['description'],
              deprecationReason: value['deprecationReason'],
            );
          }).toList(),
    description: enumIntrospection['description'],
  );
}
