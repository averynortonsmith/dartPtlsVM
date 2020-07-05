
import "package:dartz/dartz.dart" as dartz;

import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsDict extends PtlsValue {
  dartz.IHashMap<PtlsValue, PtlsValue> map;

  // -------------------------------------------------------------------------
  
  PtlsDict(this.map);

  // -------------------------------------------------------------------------

  bool contains(PtlsValue value) {
    return map.get(value) is! dartz.None;
  }

  // -------------------------------------------------------------------------

  PtlsValue getIndex(PtlsValue rhs) {
    var result = map[rhs];

    if (result.isNone()) {
      var error = PtlsError("Index Error");
      error.message = "Given key does not exist in dict";
      throw error;
    }

    return (result as dartz.Some).value;
  }

  // -------------------------------------------------------------------------

  PtlsValue updateIndex(PtlsValue index, PtlsValue result) {
    return PtlsDict(map.put(index, result));
  }

  // -------------------------------------------------------------------------

  PtlsValue delKey(PtlsValue key) {
    return PtlsDict(map.remove(key));
  }

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getDelKey":
        return PtlsBuiltIn("!getDelKey(key)", delKey);

      case "!getKeys":
        return PtlsList.fromValues(map.keyIterable());

      case "!getVals":
        return PtlsList.fromValues(map.valueIterable());

      case "!getType":
        return PtlsLabel("PtlsDict");

      case "!getLength":
        return PtlsNumber(map.length());

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }
  
  // -------------------------------------------------------------------------

  String toString() => map.toString();
}
