
import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsString extends PtlsValue {
  String value;

  // -------------------------------------------------------------------------
  
  PtlsString(this.value); 

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getInt":
        return PtlsNumber(int.parse(value));

      case "!getFloat":
        return PtlsNumber(double.parse(value));

      case "!getString":
        return this;

      case "!getList":
        var chars = value.split("").map((char) => PtlsString(char));
        return PtlsList.fromValues(chars);

      case "!getType":
        return PtlsLabel("PtlsString");

      case "!getLength":
        return PtlsNumber(value.length);

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  bool operator==(Object other) {
    if (other is PtlsString) {
      return other.value == value;
    }

    return false;
  }

  // -------------------------------------------------------------------------

  int get hashCode => value.hashCode;

  // -------------------------------------------------------------------------

  String toString() => value;
}
