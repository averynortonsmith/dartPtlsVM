
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsList extends PtlsValue {
  Thunk headThunk;
  Thunk tailThunk;

  // -------------------------------------------------------------------------
  
  PtlsList(this.headThunk, this.tailThunk);  

  // -------------------------------------------------------------------------

  static PtlsValue fromValues(Iterable<PtlsValue> values) {
    PtlsValue result = PtlsLabel("Empty");

    for (var value in [...values].reversed) {
      var headThunk = Thunk.fromValue(value);
      var tailThunk = Thunk.fromValue(result);
      result = PtlsList(headThunk, tailThunk);
    }

    return result;
  }

  // -------------------------------------------------------------------------

  PtlsValue checkIsList() => this;

  // -------------------------------------------------------------------------

  PtlsList concat(Thunk thunk) {
    // tail values should be fully resolved
    if (tailThunk.value.isEmpty) {
      return PtlsList(headThunk, thunk);
    }

    var tailVal = tailThunk.value as PtlsList;
    var newTail = Thunk.fromValue(tailVal.concat(thunk));
    return PtlsList(headThunk, newTail);
  }

  // -------------------------------------------------------------------------

  String toString() => "PtlsList(${headThunk.value}, ${tailThunk.value})";
}
