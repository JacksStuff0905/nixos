{ lib }:

rec {
  find = model: lookup: {
    __tag__ = "find";
    __model__ = model;
    __lookup__ = lookup;
  };

  keyOf = id: {
    __tag__ = "keyof";
    __id__ = id;
  };

  context = name: {
    __tag__ = "context";
    __name__ = name;
  };

  env = name: default: {
    __tag__ = "env";
    __name__ = name;
    __default__ = default;
  };

  condition = type: value: {
    __tag__ = "condition";
    __type__ = type;
    __value__ = value;
  };

  if_ = cond: thenVal: elseVal: {
    __tag__ = "if";
    __condition__ = cond;
    __then__ = thenVal;
    __else__ = elseVal;
  };

  format = fmt: args: {
    __tag__ = "format";
    __format__ = fmt;
    __args__ = args;
  };

  isTag = v: builtins.isAttrs v && v ? "__tag__";
}
