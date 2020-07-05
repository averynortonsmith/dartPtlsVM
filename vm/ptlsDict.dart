
import "package:dartz/dartz.dart" as dartz;

import "vm.dart";

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

  String toString() => map.toString();
}
