
import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsException implements Exception {
  PtlsValue value;
  Location loc;

  // -------------------------------------------------------------------------

  PtlsException(this.value, this.loc);

  // -------------------------------------------------------------------------

  String toString() => "PtlsException(${value.runtimeType})";
}
