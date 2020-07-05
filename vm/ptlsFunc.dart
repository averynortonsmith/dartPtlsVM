
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsFunc extends PtlsValue {
  Env env;
  int instInd;
  int paramIndex;
  int arity;

  // -------------------------------------------------------------------------
  
  PtlsFunc(this.env, this.instInd, this.paramIndex, this.arity);

  // -------------------------------------------------------------------------

  String toString() => "PtlsFunc($arity)";
}
