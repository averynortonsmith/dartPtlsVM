
import "package:dartz/dartz.dart" as dartz;

import "interpreter.dart";

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

  PtlsValue getField(String name) {
    switch (name) {
      case "!getAddElem":
        return PtlsBuiltIn("!getAddElem(elem)", addElem);

      case "!getDelElem":
        return PtlsBuiltIn("!getDelElem(elem)", delElem);

      case "!getType":
        return PtlsLabel("PtlsSet");

      case "!getLength":
        return PtlsNumber(map.length());

      case "!getList":
        return PtlsList.fromValues(map.keyIterable());

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  String toString() => map.toString();
}
