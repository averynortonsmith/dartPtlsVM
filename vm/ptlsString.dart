
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsString extends PtlsValue {
  String value;

  // -------------------------------------------------------------------------
  
  PtlsString(this.value); 

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
