
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsBool extends PtlsValue {
  bool value;

  // -------------------------------------------------------------------------
  
  PtlsBool(this.value);  

  // -------------------------------------------------------------------------

  static var trueVal = PtlsBool(true);
  static var falseVal = PtlsBool(false);

  static PtlsBool loadBool(bool value) => value ? trueVal : falseVal;

  // -------------------------------------------------------------------------

  bool operator==(Object other) {
    if (other is PtlsBool) {
      return other.value == value;
    }

    return false;
  }

  // -------------------------------------------------------------------------

  int get hashCode => value.hashCode;

  // -------------------------------------------------------------------------

  String toString() => value.toString();
}
