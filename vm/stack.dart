
import "vm.dart";

// ---------------------------------------------------------------------------

class Stack {
  var stackInd = 0;
  var stackVals = List<PtlsValue>(1000);

  // -------------------------------------------------------------------------

  PtlsValue getTOS() => stackVals[stackInd - 1];
  
  // -------------------------------------------------------------------------

  PtlsValue checkTOS(List<Type> types) => getTOS().checkType(types);

  // -------------------------------------------------------------------------

  void pushValue(PtlsValue value) => stackVals[stackInd++] = value;
  
  // -------------------------------------------------------------------------

  PtlsValue popValue() {
    var value = stackVals[--stackInd];
    // get rid of ref still on stack
    stackVals[stackInd] = null;
    return value;
  }

  // -------------------------------------------------------------------------

  PtlsValue popCheck(List<Type> types) => popValue().checkType(types);
}
