
import "interpreter.dart";

// ---------------------------------------------------------------------------

class Thunk {
  String name;
  Function func;
  PtlsValue value;
  int index;
  var lock = false;

  // -------------------------------------------------------------------------

  Thunk(this.name, this.func);

  // -------------------------------------------------------------------------

  static fromValue(String name, PtlsValue val) {
    var thunk = Thunk(name, null);
    thunk.value = val;
    return thunk;
  }

  // -------------------------------------------------------------------------

  PtlsValue getValue() {
    if (value == null) {
      checkLock();
      lock = true;
      value = func();
      lock = false;
    }
    return value;
  }

  // -------------------------------------------------------------------------

  void checkLock() {
    if (lock) {
      var error = PtlsError("Name Error");
      error.message = "Circular definition for name '$name'";
      throw error;
    }
  }
}
