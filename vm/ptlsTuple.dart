
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsTuple extends PtlsValue {
  PtlsLabel label;
  List<PtlsValue> members;
  static var defaultLabel = PtlsLabel("PtlsTuple");

  // -------------------------------------------------------------------------
  
  PtlsTuple(this.label, this.members);

  // -------------------------------------------------------------------------

  PtlsValue checkLength(int length) {
    if (length != members.length) {
      var error = PtlsError("Type Error");
      error.message = 
        "Cannot destructure length $length tuple to ${members.length} names";
      throw error;
    }

    return this;
  }

  // -------------------------------------------------------------------------

  PtlsValue getMember(int index) {
    return members[index];
  }

  // -------------------------------------------------------------------------

  bool operator==(Object other) {
    if (other is PtlsTuple) {
      if (label != other.label) {
        return false;
      }

      if (members.length != other.members.length) {
        return false;
      }

      for (var i = 0; i < members.length; i++) {
        if (members[i] != other.members[i]) {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  // -------------------------------------------------------------------------

  int get hashCode {
    var result = 0;

    for (var member in members) {
      result += member.hashCode;
      result *= 7;
    }

    return result;
  }

  // -------------------------------------------------------------------------

  String toString() => "$label(${members.join(", ")})";
}
