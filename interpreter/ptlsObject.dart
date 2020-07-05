
import "package:dartz/dartz.dart" as dartz;

import "interpreter.dart";

// ---------------------------------------------------------------------------

class PtlsObject extends PtlsValue {
  Env env;

  // -------------------------------------------------------------------------
  
  PtlsObject(this.env);  

  // -------------------------------------------------------------------------

  PtlsValue getField(String name) {
    if (env.defs.containsKey(name)) {
      return env.lookupName(name);
    }

    switch (name) {
      case "!getType":
        return PtlsLabel("PtlsObject");

      case "!getDict":
        var map = dartz.IHashMap<PtlsValue, PtlsValue>.from({
          for (var name in env.defs.keys)
          PtlsString(name): env.lookupName(name)
        });
        return PtlsDict(map);

      default: super.getField(name);
    }

    var error = PtlsError("Type Error");
    var fields = env.defs.keys.join(", ");
    error.message = "Invalid field '$name' for Object with fields {$fields}";
    throw error;
  }

  // -------------------------------------------------------------------------

  PtlsValue updateField(String name, PtlsValue result) {
    var newEnv = env.clone();

    if (newEnv.defs.containsKey(name)) {
      newEnv.defs.remove(name);
    }

    var thunk = Thunk.fromValue(name, result);
    newEnv.addDefThunk(thunk);
    return PtlsObject(newEnv);
  }

  // -------------------------------------------------------------------------

  String toString() => env.defs.toString();
}
