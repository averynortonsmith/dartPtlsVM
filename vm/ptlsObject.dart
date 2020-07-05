
import "vm.dart";

// ---------------------------------------------------------------------------

class PtlsObject extends PtlsValue {
  Env env;

  // -------------------------------------------------------------------------
  
  PtlsObject(this.env);  

  // -------------------------------------------------------------------------

  PtlsValue updateField(String name, PtlsValue result) {
    // var newEnv = env.clone();
    // var index = newEnv.defs.indexWhere((def) => def.name = )

    // if () {
    //   newEnv.defs.remove(name);
    // }

    // var thunk = Thunk.fromValue(name, result);
    // newEnv.addDefThunk(thunk);
    // return PtlsObject(newEnv);
  }

  // -------------------------------------------------------------------------

  String toString() => env.defs.toString();
}
