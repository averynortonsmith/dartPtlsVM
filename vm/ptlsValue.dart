
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsValue {
  Location loc;

  // -------------------------------------------------------------------------

  bool contains(PtlsValue value) {
    checkType([PtlsDict, PtlsSet]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue getMember(int index) {
    checkType([PtlsTuple]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue getIndex(PtlsValue rhs) {
    checkType([PtlsDict, PtlsArray]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue updateIndex(PtlsValue index, PtlsValue result) {
    checkType([PtlsDict, PtlsArray]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    // if is language field
    if (name[0] == "!") {
      var error = PtlsError("Type Error");
      error.message = "No built-in field '$name' for type '$runtimeType'";
      throw error;
    }

    checkType([PtlsObject]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue updateField(String name, PtlsValue result) {
    checkType([PtlsObject]); // throw error
    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue checkType(List<Type> types) {
    if (!types.contains(runtimeType)) {
      var typesStr = types.join(" or ");
      var error = PtlsError("Type Error");
      error.message = "Expected type '$typesStr', got '$runtimeType'";
      throw error;
    }

    return this;
  }

  // -------------------------------------------------------------------------

  bool get isEmpty => false;

  PtlsValue checkIsList() {
    var error = PtlsError("Type Error");
    error.message = "Expected type 'PtlsList or Empty', got '$runtimeType'";
    throw error;
  }

  // -------------------------------------------------------------------------

  int get hashCode {
    var error = PtlsError("Type Error");
    error.message = "Cannot hash type '$runtimeType'";
    throw error;
  }
}
