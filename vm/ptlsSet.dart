
import "package:dartz/dartz.dart" as dartz;

import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsSet extends PtlsValue {
  dartz.IHashMap<PtlsValue, PtlsValue> map;

  // -------------------------------------------------------------------------
  
  PtlsSet(this.map);

  // -------------------------------------------------------------------------

  bool contains(PtlsValue value) {
    return map.get(value) is! dartz.None;
  }

  // -------------------------------------------------------------------------

  PtlsValue addElem(PtlsValue elem) {
    return PtlsSet(map.put(elem, null));
  }

  // -------------------------------------------------------------------------

  PtlsValue delElem(PtlsValue elem) {
    return PtlsSet(map.remove(elem));
  }

  // -------------------------------------------------------------------------

  String toString() => map.toString();
}
