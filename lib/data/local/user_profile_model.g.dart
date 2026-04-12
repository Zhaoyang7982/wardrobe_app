// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserProfileModelCollection on Isar {
  IsarCollection<UserProfileModel> get userProfileModels => this.collection();
}

const UserProfileModelSchema = CollectionSchema(
  name: r'UserProfileModel',
  id: -8790468936041821297,
  properties: {
    r'bodyType': PropertySchema(
      id: 0,
      name: r'bodyType',
      type: IsarType.string,
    ),
    r'favoriteColors': PropertySchema(
      id: 1,
      name: r'favoriteColors',
      type: IsarType.stringList,
    ),
    r'favoriteOccasions': PropertySchema(
      id: 2,
      name: r'favoriteOccasions',
      type: IsarType.stringList,
    ),
    r'height': PropertySchema(
      id: 3,
      name: r'height',
      type: IsarType.double,
    ),
    r'profileId': PropertySchema(
      id: 4,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'styles': PropertySchema(
      id: 5,
      name: r'styles',
      type: IsarType.stringList,
    ),
    r'weight': PropertySchema(
      id: 6,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _userProfileModelEstimateSize,
  serialize: _userProfileModelSerialize,
  deserialize: _userProfileModelDeserialize,
  deserializeProp: _userProfileModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'profileId': IndexSchema(
      id: 6052971939042612300,
      name: r'profileId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'profileId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userProfileModelGetId,
  getLinks: _userProfileModelGetLinks,
  attach: _userProfileModelAttach,
  version: '3.1.0+1',
);

int _userProfileModelEstimateSize(
  UserProfileModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.bodyType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.favoriteColors.length * 3;
  {
    for (var i = 0; i < object.favoriteColors.length; i++) {
      final value = object.favoriteColors[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.favoriteOccasions.length * 3;
  {
    for (var i = 0; i < object.favoriteOccasions.length; i++) {
      final value = object.favoriteOccasions[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.profileId.length * 3;
  bytesCount += 3 + object.styles.length * 3;
  {
    for (var i = 0; i < object.styles.length; i++) {
      final value = object.styles[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _userProfileModelSerialize(
  UserProfileModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bodyType);
  writer.writeStringList(offsets[1], object.favoriteColors);
  writer.writeStringList(offsets[2], object.favoriteOccasions);
  writer.writeDouble(offsets[3], object.height);
  writer.writeString(offsets[4], object.profileId);
  writer.writeStringList(offsets[5], object.styles);
  writer.writeDouble(offsets[6], object.weight);
}

UserProfileModel _userProfileModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserProfileModel();
  object.bodyType = reader.readStringOrNull(offsets[0]);
  object.favoriteColors = reader.readStringList(offsets[1]) ?? [];
  object.favoriteOccasions = reader.readStringList(offsets[2]) ?? [];
  object.height = reader.readDoubleOrNull(offsets[3]);
  object.id = id;
  object.profileId = reader.readString(offsets[4]);
  object.styles = reader.readStringList(offsets[5]) ?? [];
  object.weight = reader.readDoubleOrNull(offsets[6]);
  return object;
}

P _userProfileModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userProfileModelGetId(UserProfileModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userProfileModelGetLinks(UserProfileModel object) {
  return [];
}

void _userProfileModelAttach(
    IsarCollection<dynamic> col, Id id, UserProfileModel object) {
  object.id = id;
}

extension UserProfileModelByIndex on IsarCollection<UserProfileModel> {
  Future<UserProfileModel?> getByProfileId(String profileId) {
    return getByIndex(r'profileId', [profileId]);
  }

  UserProfileModel? getByProfileIdSync(String profileId) {
    return getByIndexSync(r'profileId', [profileId]);
  }

  Future<bool> deleteByProfileId(String profileId) {
    return deleteByIndex(r'profileId', [profileId]);
  }

  bool deleteByProfileIdSync(String profileId) {
    return deleteByIndexSync(r'profileId', [profileId]);
  }

  Future<List<UserProfileModel?>> getAllByProfileId(
      List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'profileId', values);
  }

  List<UserProfileModel?> getAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'profileId', values);
  }

  Future<int> deleteAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'profileId', values);
  }

  int deleteAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'profileId', values);
  }

  Future<Id> putByProfileId(UserProfileModel object) {
    return putByIndex(r'profileId', object);
  }

  Id putByProfileIdSync(UserProfileModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'profileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProfileId(List<UserProfileModel> objects) {
    return putAllByIndex(r'profileId', objects);
  }

  List<Id> putAllByProfileIdSync(List<UserProfileModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'profileId', objects, saveLinks: saveLinks);
  }
}

extension UserProfileModelQueryWhereSort
    on QueryBuilder<UserProfileModel, UserProfileModel, QWhere> {
  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserProfileModelQueryWhere
    on QueryBuilder<UserProfileModel, UserProfileModel, QWhereClause> {
  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause>
      profileIdEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'profileId',
        value: [profileId],
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterWhereClause>
      profileIdNotEqualTo(String profileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserProfileModelQueryFilter
    on QueryBuilder<UserProfileModel, UserProfileModel, QFilterCondition> {
  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyType',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyType',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bodyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bodyType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      bodyTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bodyType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favoriteColors',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'favoriteColors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'favoriteColors',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteColors',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'favoriteColors',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteColorsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteColors',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favoriteOccasions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'favoriteOccasions',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'favoriteOccasions',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteOccasions',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'favoriteOccasions',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      favoriteOccasionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteOccasions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      heightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      profileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'styles',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'styles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'styles',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'styles',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'styles',
        value: '',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      stylesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'styles',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterFilterCondition>
      weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension UserProfileModelQueryObject
    on QueryBuilder<UserProfileModel, UserProfileModel, QFilterCondition> {}

extension UserProfileModelQueryLinks
    on QueryBuilder<UserProfileModel, UserProfileModel, QFilterCondition> {}

extension UserProfileModelQuerySortBy
    on QueryBuilder<UserProfileModel, UserProfileModel, QSortBy> {
  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByBodyType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyType', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByBodyTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyType', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension UserProfileModelQuerySortThenBy
    on QueryBuilder<UserProfileModel, UserProfileModel, QSortThenBy> {
  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByBodyType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyType', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByBodyTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyType', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QAfterSortBy>
      thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension UserProfileModelQueryWhereDistinct
    on QueryBuilder<UserProfileModel, UserProfileModel, QDistinct> {
  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByBodyType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByFavoriteColors() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favoriteColors');
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByFavoriteOccasions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favoriteOccasions');
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByProfileId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByStyles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'styles');
    });
  }

  QueryBuilder<UserProfileModel, UserProfileModel, QDistinct>
      distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension UserProfileModelQueryProperty
    on QueryBuilder<UserProfileModel, UserProfileModel, QQueryProperty> {
  QueryBuilder<UserProfileModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserProfileModel, String?, QQueryOperations> bodyTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyType');
    });
  }

  QueryBuilder<UserProfileModel, List<String>, QQueryOperations>
      favoriteColorsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favoriteColors');
    });
  }

  QueryBuilder<UserProfileModel, List<String>, QQueryOperations>
      favoriteOccasionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favoriteOccasions');
    });
  }

  QueryBuilder<UserProfileModel, double?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<UserProfileModel, String, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<UserProfileModel, List<String>, QQueryOperations>
      stylesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'styles');
    });
  }

  QueryBuilder<UserProfileModel, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
