
import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsNumber extends PtlsValue {
  num value;

  // -------------------------------------------------------------------------
  
  PtlsNumber(this.value);

  // -------------------------------------------------------------------------

  bool operator==(Object other) {
    if (other is PtlsNumber) {
      return other.value == value;
    }

    return false;
  }

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getInt":
        return PtlsNumber(value.toInt());

      case "!getFloat":
        return PtlsNumber(value.toDouble());

      case "!getString":
        return PtlsString(value.toString());

      case "!getType":
        return PtlsLabel("PtlsNumber");

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  int get hashCode => value.hashCode;

  // -------------------------------------------------------------------------

  String toString() => value.toString();
}
