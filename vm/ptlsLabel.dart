
import "dart:io";
import "package:dartz/dartz.dart" as dartz;

import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsLabel extends PtlsValue {
  String value;

  // -------------------------------------------------------------------------
  
  PtlsLabel(this.value);  

  // -------------------------------------------------------------------------

  static PtlsValue get empty => PtlsLabel("Empty");

  // -------------------------------------------------------------------------
  
  bool get isEmpty => value == "Empty";

  // -------------------------------------------------------------------------

  PtlsValue checkIsList() {
    if (isEmpty) {
      return this;
    }

    super.checkIsList(); // throws error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue getZeros(PtlsValue val) {
    var n = (val.checkType([PtlsNumber]) as PtlsNumber).value;
    var zeros = List.filled(n, PtlsNumber(0));
    return PtlsArray(dartz.IVector.from(zeros));
  }

  // -------------------------------------------------------------------------

  PtlsValue getLine() {
    var line = stdin.readLineSync();
    if (line == null) {
      return PtlsLabel("Empty");
    }

    return PtlsString(line);
  }

  // -------------------------------------------------------------------------

  PtlsValue getLines() {
    var headThunk = LangThunk(getLine);
    var tailThunk = LangThunk(getLines);
    return PtlsList(headThunk, tailThunk);
  }

  // -------------------------------------------------------------------------

  void checkLabel(String val, String name) {
    if (value != val) {
      var error = PtlsError("Type Error");
      error.message = "No built-in field '$name' for label '$value'";
      throw error;
    }
  }

  // -------------------------------------------------------------------------

  bool operator==(Object other) {
    if (other is PtlsLabel) {
      return other.value == value;
    }

    return false;
  }

  // -------------------------------------------------------------------------

  int get hashCode => value.hashCode;

  // -------------------------------------------------------------------------
  
  String toString() => value;
}
