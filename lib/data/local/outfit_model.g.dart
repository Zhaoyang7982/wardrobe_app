// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOutfitModelCollection on Isar {
  IsarCollection<OutfitModel> get outfitModels => this.collection();
}

const OutfitModelSchema = CollectionSchema(
  name: r'OutfitModel',
  id: -482877122969459788,
  properties: {
    r'clothingIds': PropertySchema(
      id: 0,
      name: r'clothingIds',
      type: IsarType.stringList,
    ),
    r'imageUrl': PropertySchema(
      id: 1,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'isArchived': PropertySchema(
      id: 2,
      name: r'isArchived',
      type: IsarType.bool,
    ),
    r'isShared': PropertySchema(
      id: 3,
      name: r'isShared',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 5,
      name: r'notes',
      type: IsarType.string,
    ),
    r'occasion': PropertySchema(
      id: 6,
      name: r'occasion',
      type: IsarType.string,
    ),
    r'outfitId': PropertySchema(
      id: 7,
      name: r'outfitId',
      type: IsarType.string,
    ),
    r'plannedDates': PropertySchema(
      id: 8,
      name: r'plannedDates',
      type: IsarType.dateTimeList,
    ),
    r'scene': PropertySchema(
      id: 9,
      name: r'scene',
      type: IsarType.string,
    ),
    r'season': PropertySchema(
      id: 10,
      name: r'season',
      type: IsarType.string,
    ),
    r'wornDates': PropertySchema(
      id: 11,
      name: r'wornDates',
      type: IsarType.dateTimeList,
    )
  },
  estimateSize: _outfitModelEstimateSize,
  serialize: _outfitModelSerialize,
  deserialize: _outfitModelDeserialize,
  deserializeProp: _outfitModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'outfitId': IndexSchema(
      id: 2088527764185479769,
      name: r'outfitId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'outfitId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _outfitModelGetId,
  getLinks: _outfitModelGetLinks,
  attach: _outfitModelAttach,
  version: '3.1.0+1',
);

int _outfitModelEstimateSize(
  OutfitModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clothingIds.length * 3;
  {
    for (var i = 0; i < object.clothingIds.length; i++) {
      final value = object.clothingIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.imageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.occasion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.outfitId.length * 3;
  bytesCount += 3 + object.plannedDates.length * 8;
  {
    final value = object.scene;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.season;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.wornDates.length * 8;
  return bytesCount;
}

void _outfitModelSerialize(
  OutfitModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.clothingIds);
  writer.writeString(offsets[1], object.imageUrl);
  writer.writeBool(offsets[2], object.isArchived);
  writer.writeBool(offsets[3], object.isShared);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.notes);
  writer.writeString(offsets[6], object.occasion);
  writer.writeString(offsets[7], object.outfitId);
  writer.writeDateTimeList(offsets[8], object.plannedDates);
  writer.writeString(offsets[9], object.scene);
  writer.writeString(offsets[10], object.season);
  writer.writeDateTimeList(offsets[11], object.wornDates);
}

OutfitModel _outfitModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutfitModel();
  object.clothingIds = reader.readStringList(offsets[0]) ?? [];
  object.id = id;
  object.imageUrl = reader.readStringOrNull(offsets[1]);
  object.isArchived = reader.readBool(offsets[2]);
  object.isShared = reader.readBool(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.notes = reader.readStringOrNull(offsets[5]);
  object.occasion = reader.readStringOrNull(offsets[6]);
  object.outfitId = reader.readString(offsets[7]);
  object.plannedDates = reader.readDateTimeList(offsets[8]) ?? [];
  object.scene = reader.readStringOrNull(offsets[9]);
  object.season = reader.readStringOrNull(offsets[10]);
  object.wornDates = reader.readDateTimeList(offsets[11]) ?? [];
  return object;
}

P _outfitModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTimeList(offset) ?? []) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _outfitModelGetId(OutfitModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _outfitModelGetLinks(OutfitModel object) {
  return [];
}

void _outfitModelAttach(
    IsarCollection<dynamic> col, Id id, OutfitModel object) {
  object.id = id;
}

extension OutfitModelByIndex on IsarCollection<OutfitModel> {
  Future<OutfitModel?> getByOutfitId(String outfitId) {
    return getByIndex(r'outfitId', [outfitId]);
  }

  OutfitModel? getByOutfitIdSync(String outfitId) {
    return getByIndexSync(r'outfitId', [outfitId]);
  }

  Future<bool> deleteByOutfitId(String outfitId) {
    return deleteByIndex(r'outfitId', [outfitId]);
  }

  bool deleteByOutfitIdSync(String outfitId) {
    return deleteByIndexSync(r'outfitId', [outfitId]);
  }

  Future<List<OutfitModel?>> getAllByOutfitId(List<String> outfitIdValues) {
    final values = outfitIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'outfitId', values);
  }

  List<OutfitModel?> getAllByOutfitIdSync(List<String> outfitIdValues) {
    final values = outfitIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'outfitId', values);
  }

  Future<int> deleteAllByOutfitId(List<String> outfitIdValues) {
    final values = outfitIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'outfitId', values);
  }

  int deleteAllByOutfitIdSync(List<String> outfitIdValues) {
    final values = outfitIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'outfitId', values);
  }

  Future<Id> putByOutfitId(OutfitModel object) {
    return putByIndex(r'outfitId', object);
  }

  Id putByOutfitIdSync(OutfitModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'outfitId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOutfitId(List<OutfitModel> objects) {
    return putAllByIndex(r'outfitId', objects);
  }

  List<Id> putAllByOutfitIdSync(List<OutfitModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'outfitId', objects, saveLinks: saveLinks);
  }
}

extension OutfitModelQueryWhereSort
    on QueryBuilder<OutfitModel, OutfitModel, QWhere> {
  QueryBuilder<OutfitModel, OutfitModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OutfitModelQueryWhere
    on QueryBuilder<OutfitModel, OutfitModel, QWhereClause> {
  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> outfitIdEqualTo(
      String outfitId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'outfitId',
        value: [outfitId],
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterWhereClause> outfitIdNotEqualTo(
      String outfitId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'outfitId',
              lower: [],
              upper: [outfitId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'outfitId',
              lower: [outfitId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'outfitId',
              lower: [outfitId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'outfitId',
              lower: [],
              upper: [outfitId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OutfitModelQueryFilter
    on QueryBuilder<OutfitModel, OutfitModel, QFilterCondition> {
  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clothingIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clothingIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clothingIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clothingIds',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clothingIds',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      clothingIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clothingIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> imageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> imageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> imageUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      isArchivedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isArchived',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> isSharedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isShared',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'occasion',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'occasion',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> occasionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> occasionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'occasion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'occasion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> occasionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'occasion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'occasion',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      occasionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'occasion',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> outfitIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> outfitIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outfitId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outfitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> outfitIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outfitId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outfitId',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      outfitIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outfitId',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesElementEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'plannedDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesElementGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'plannedDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesElementLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'plannedDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesElementBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'plannedDates',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      plannedDatesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'plannedDates',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scene',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      sceneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scene',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      sceneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scene',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scene',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scene',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> sceneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scene',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      sceneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scene',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'season',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      seasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'season',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      seasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'season',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      seasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'season',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition> seasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'season',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      seasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'season',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      seasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'season',
        value: '',
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesElementEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wornDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesElementGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wornDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesElementLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wornDates',
        value: value,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesElementBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wornDates',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterFilterCondition>
      wornDatesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'wornDates',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension OutfitModelQueryObject
    on QueryBuilder<OutfitModel, OutfitModel, QFilterCondition> {}

extension OutfitModelQueryLinks
    on QueryBuilder<OutfitModel, OutfitModel, QFilterCondition> {}

extension OutfitModelQuerySortBy
    on QueryBuilder<OutfitModel, OutfitModel, QSortBy> {
  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByIsShared() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isShared', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByIsSharedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isShared', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByOccasion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occasion', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByOccasionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occasion', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByOutfitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outfitId', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByOutfitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outfitId', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortByScene() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scene', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortBySceneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scene', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortBySeason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> sortBySeasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.desc);
    });
  }
}

extension OutfitModelQuerySortThenBy
    on QueryBuilder<OutfitModel, OutfitModel, QSortThenBy> {
  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByIsArchivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isArchived', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByIsShared() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isShared', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByIsSharedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isShared', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByOccasion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occasion', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByOccasionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occasion', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByOutfitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outfitId', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByOutfitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outfitId', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenByScene() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scene', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenBySceneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scene', Sort.desc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenBySeason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.asc);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QAfterSortBy> thenBySeasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'season', Sort.desc);
    });
  }
}

extension OutfitModelQueryWhereDistinct
    on QueryBuilder<OutfitModel, OutfitModel, QDistinct> {
  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByClothingIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clothingIds');
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByIsArchived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isArchived');
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByIsShared() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isShared');
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByOccasion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occasion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByOutfitId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outfitId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByPlannedDates() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'plannedDates');
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByScene(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scene', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctBySeason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'season', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutfitModel, OutfitModel, QDistinct> distinctByWornDates() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wornDates');
    });
  }
}

extension OutfitModelQueryProperty
    on QueryBuilder<OutfitModel, OutfitModel, QQueryProperty> {
  QueryBuilder<OutfitModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OutfitModel, List<String>, QQueryOperations>
      clothingIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clothingIds');
    });
  }

  QueryBuilder<OutfitModel, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<OutfitModel, bool, QQueryOperations> isArchivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isArchived');
    });
  }

  QueryBuilder<OutfitModel, bool, QQueryOperations> isSharedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isShared');
    });
  }

  QueryBuilder<OutfitModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<OutfitModel, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<OutfitModel, String?, QQueryOperations> occasionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occasion');
    });
  }

  QueryBuilder<OutfitModel, String, QQueryOperations> outfitIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outfitId');
    });
  }

  QueryBuilder<OutfitModel, List<DateTime>, QQueryOperations>
      plannedDatesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'plannedDates');
    });
  }

  QueryBuilder<OutfitModel, String?, QQueryOperations> sceneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scene');
    });
  }

  QueryBuilder<OutfitModel, String?, QQueryOperations> seasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'season');
    });
  }

  QueryBuilder<OutfitModel, List<DateTime>, QQueryOperations>
      wornDatesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wornDates');
    });
  }
}
