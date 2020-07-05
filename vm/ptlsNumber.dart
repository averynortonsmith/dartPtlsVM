
import "vm.dart";

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

  int get hashCode => value.hashCode;

  // -------------------------------------------------------------------------

  String toString() => value.toString();
}
