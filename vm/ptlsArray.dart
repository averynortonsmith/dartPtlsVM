
import "package:dartz/dartz.dart" as dartz;

import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsArray extends PtlsValue {
  dartz.IVector<PtlsValue> elems;

  // -------------------------------------------------------------------------
  
  PtlsArray(this.elems);

  // -------------------------------------------------------------------------

  List<PtlsValue> get elemsList => [...elems.toIterable()];

  // -------------------------------------------------------------------------

  int checkIndex(num index) {
    if (index.toInt() != index) {
      var error = PtlsError("Index Error");
      error.message = "Expected integer index value, got $index";
      throw error;
    }

    if (index < 0 || index >= elems.length()) {
      var error = PtlsError("Index Error");
      var len = elems.length();
      error.message = "Invalid index $index, for array with length $len";
      throw error;
    }

    return index.toInt();
  }

  // -------------------------------------------------------------------------

  PtlsValue getIndex(PtlsValue rhs) {
    PtlsNumber numVal = rhs.checkType([PtlsNumber]);
    var index = checkIndex(numVal.value);
    return (elems[index] as dartz.Some).value;
  }

  // -------------------------------------------------------------------------

  PtlsValue updateIndex(PtlsValue index, PtlsValue result) {
    PtlsNumber numVal = index.checkType([PtlsNumber]);
    var ind = checkIndex(numVal.value);
    return PtlsArray(elems.setIfPresent(ind, result));
  }

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getList":
        return PtlsList.fromValues(elems.toIterable());

      case "!getType":
        return PtlsLabel("PtlsArray");

      case "!getLength":
        return PtlsNumber(elems.length());

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  String toString() => elems.toString();
}
