
import "vm.dart";

// ---------------------------------------------------------------------------

class Thunk {
  PtlsValue value;
  Env env;
  int instInd;

  var lock = false;

  // -------------------------------------------------------------------------

  Thunk(this.env, this.instInd);

  // -------------------------------------------------------------------------

  bool get hasValue => value != null;

  // -------------------------------------------------------------------------

  static fromValue(PtlsValue value) {
    var thunk = Thunk(null, null);
    thunk.value = value;
    return thunk;
  }
}

// ---------------------------------------------------------------------------

class LangThunk extends Thunk {
  Function handler;
  PtlsValue cacheVal;

  // -------------------------------------------------------------------------

  LangThunk(this.handler): super(null, null);

  // -------------------------------------------------------------------------

  bool get hasValue => value != null;

  // -------------------------------------------------------------------------

  PtlsValue get value {
    cacheVal ??= handler();
    return cacheVal;
  }
}
