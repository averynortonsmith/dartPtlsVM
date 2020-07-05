
import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsFunc extends PtlsValue {
  Env env;
  List<String> params;
  ASTNode body;

  // -------------------------------------------------------------------------
  
  PtlsFunc(this.env, this.params, this.body);

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    switch (name) {
      case "!getType":
        return PtlsLabel("PtlsFunc");

      default: super.getField(name); // throws error
    }

    throw false; // should never get here
  }

  // -------------------------------------------------------------------------

  String toString() {
    var partParams = params.getRange(0, env.defs.length).join(", ");
    var newParams = params.getRange(env.defs.length, params.length).join(", ");

    if (partParams.isEmpty) {
      return "PtlsFunc($newParams)";

    } else {
      return "PtlsFunc($partParams)($newParams)";
    }
  }
}
