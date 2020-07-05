
import "vm.dart";

// ---------------------------------------------------------------------------

class Def {
  int instInd;
  String name;
  PtlsValue value;
  bool exported;
  // def needs to track original env  for SaveVal if it's copied as upval
  Env originalEnv;
  bool lock = false;

  // ---------------------------------------------------------------------------

  Def(this.instInd, this.name);

  // ---------------------------------------------------------------------------

  bool get hasValue => value != null;

  // ---------------------------------------------------------------------------

  static Def fromValue(PtlsValue value, String name) {
    var def = Def(null, name);
    def.value = value;
    return def;
  }

  // ---------------------------------------------------------------------------

  void checkLock() {
    if (lock) {
      var error = PtlsError("Definition Error");
      error.message = "Circular definition for name '$name'";
      throw error;
    }
  }
}

// ---------------------------------------------------------------------------

class Env {
  // env needs to keep track of its own globals
  // important for making loadGlobal work in code loaded from
  // another file (with import) - can't use globals from current file
  Env globals;
  List<Def> defs;
  bool exportAll = true;

  // -------------------------------------------------------------------------

  Env(int numDefs, this.globals) {
    // use growable list for zero defs length
    // (used for MakeEnv with SaveExport)
    defs = numDefs > 0 ? List(numDefs) : [];
  }

  // -------------------------------------------------------------------------

  void addDef(Def def, int index) {
    defs[index] = def;
    def.originalEnv ??= this;
  }

  // -------------------------------------------------------------------------

  Env clone() {
    var newEnv = Env(0, globals);
    newEnv.defs = [...defs];
    newEnv.exportAll = exportAll;
    return newEnv;
  }

  // -------------------------------------------------------------------------

  Def lookupName(String name) {
    for (var def in defs) {
      if (def.name == name) {
        return def;
      }
    }
    
    return null;
  }
}

// ---------------------------------------------------------------------------

class EnvStack {
  var envStackInd = 0;
  var envs = List<Env>(1000);
  var rets = List<int>(1000);
  Env prelude;

  // -------------------------------------------------------------------------

  Env get currentEnv => envs[envStackInd - 1];
  Env get parentEnv => envs[envStackInd - 2];
  Env get currentGlobals => currentEnv.globals;

  // -------------------------------------------------------------------------

  Env makeEnv(int numDefs) {
    if (envStackInd > 1) {
      return Env(numDefs, currentGlobals);
    }

    var env = Env(numDefs, null);
    env.globals = env;
    return env;
  }

  // -------------------------------------------------------------------------

  void pushEnv(Env env, int retInd) {
    if (envStackInd == 1000) {
      var error = PtlsError("Stack Overflow");
      error.message = "Call stack overflow";
      throw error;
    }

    rets[envStackInd] = retInd;
    envs[envStackInd] = env;
    envStackInd++;
  }
  
  // -------------------------------------------------------------------------

  void popEnv() {
    --envStackInd;
    if (rets[envStackInd] != null) {
      // these envs should always be pop'd, not return'd
      throw false;
    }
  }

  // -------------------------------------------------------------------------

  int popReturn() {
    --envStackInd;
    if (rets[envStackInd] == null) {
      // these envs should always be return'd, not return'd
      throw false;
    }
    return rets[envStackInd];
  }
}
