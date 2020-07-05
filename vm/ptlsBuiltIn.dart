
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsBuiltIn extends PtlsValue {
  String signature;
  Function handler;

  // -------------------------------------------------------------------------
  
  PtlsBuiltIn(this.signature, this.handler);

  // -------------------------------------------------------------------------

  String toString() => "PtlsBuiltIn($signature)";
}
