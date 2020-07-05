
import "interpreter.dart";

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
      var headThunk = Thunk.fromValue("", value);
      var tailThunk = Thunk.fromValue("", result);
      result = PtlsList(headThunk, tailThunk);
    }

    return result;
  }

  // -------------------------------------------------------------------------

  PtlsValue checkIsList() => this;

  // -------------------------------------------------------------------------

  PtlsValue get head => headThunk.getValue();
  PtlsValue get tail => tailThunk.getValue();

  // -------------------------------------------------------------------------

  String toString() => "($head, $tail)";

  // -------------------------------------------------------------------------

  List<PtlsValue> toList() {
    var tailIter = tail;
    var result = [head];

    while (!tailIter.isEmpty) {
      result.add((tailIter as PtlsList).head);
      tailIter = (tailIter as PtlsList).tail;
    }

    return result;
  }

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getHead":
        return head;

      case "!getTail":
        return tail;

      case "!getList":
        return this;

      case "!getType":
        return PtlsLabel("PtlsList");

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  PtlsValue concat(Env env, ASTNode rhsNode) {
    if (tail.isEmpty) {
      var thunk = Thunk("", () => eval(env, rhsNode).checkIsList());
      return PtlsList(headThunk, thunk);
    }

    var thunk = Thunk("", () => (tail as PtlsList).concat(env, rhsNode));
    return PtlsList(headThunk, thunk);
  }
}
