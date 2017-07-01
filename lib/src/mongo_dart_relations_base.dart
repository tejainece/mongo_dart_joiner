// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:jaguar_serializer/serializer.dart';

typedef FieldType IdGetter<ModelType, FieldType>(ModelType model);

typedef void IdSetter<ParentType, ChildType>(ParentType model, ChildType field);

/// Joins
class Joiner<ParentType, ChildType, FieldType> {
  final DbCollection col;

  final Serializer<ChildType> serializier;

  final String fieldName;

  IdGetter<ParentType, FieldType> _getter;

  IdSetter<ParentType, ChildType> _setter;

  Joiner(this.col, this.serializier, this.fieldName);

  void withGetter(IdGetter<ParentType, FieldType> getter) => _getter = getter;

  void withSetter(IdSetter<ParentType, ChildType> setter) => _setter = setter;

  Future<Map<FieldType, ChildType>> get(List<ParentType> model) async {
    final _fields = new Set<FieldType>();

    model.map(_getter).where((FieldType f) => f != null).forEach(_fields.add);

    final SelectorBuilder ors = where;

    _fields.forEach((FieldType id) {
      ors.eq(fieldName, id);
    });

    List<Map> data = await (await col.find(where.or(ors))).toList();

    final ret = <FieldType, ChildType>{};
    data.map((Map map) {
      final ChildType model = serializier.fromMap(map);
      ret[map[fieldName]] = model;
    });
    return ret;
  }

  Future<Null> join(List<ParentType> model) async {
    Map<FieldType, ChildType> data = await get(model);

    model.forEach((ParentType m) {
      final FieldType field = _getter(m);

      final ChildType child = data[field];

      if(child == null) return;
      _setter(m, child);
    });
  }
}