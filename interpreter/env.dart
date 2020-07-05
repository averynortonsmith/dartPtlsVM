
import "interpreter.dart";

// ---------------------------------------------------------------------------

class Env {
  Env parent;
  Env prelude;
  Env globals;
  Map<String, Thunk> defs = {};

  // -------------------------------------------------------------------------

  Env(this.parent) {
    this.prelude = parent?.prelude ?? this;
    this.globals = parent?.globals ?? parent ?? this;
  }

  // -------------------------------------------------------------------------

  static Map<SourceFile, Env> envCache = {};

  static Env loadEnv(SourceFile source) {
    if (!envCache.containsKey(source)) {

      var parent =
        source != SourceFile.prelude
        ? Env.loadEnv(SourceFile.prelude)
        : null;

      envCache[source] = Env(parent);
      eval(envCache[source], source.getNode());
    }

    return envCache[source];
  }

  // -------------------------------------------------------------------------

  Env spawn() => Env(this);

  Env clone() {
    var newEnv = Env(parent);
    newEnv.defs = {...defs};
    return newEnv;
  }

  // -------------------------------------------------------------------------

  addDef(ASTNode defNode) {
    ASTNode lhs = defNode[0];
    ASTNode rhs = defNode[1];

    if (lhs.nodeType == Node.Name) {
      addDefName(lhs[0], rhs);
      return;
    }

    if (lhs.nodeType == Node.Tuple) {
      addDefTuple(lhs[0], rhs);
      return;
    }

    throw false;
  }

  // -------------------------------------------------------------------------

  addDefThunk(Thunk thunk) {
    if (defs.containsKey(thunk.name)) {
      var error = PtlsError("Name Error");
      error.message = "Duplicate definition for name '${thunk.name}'";
      throw error;
    }

    defs[thunk.name] = thunk;
    thunk.index = defs.length;
  }

  // -------------------------------------------------------------------------

  addDefName(String name, ASTNode rhs) {
    var thunk = Thunk(name, () => eval(this, rhs));
    addDefThunk(thunk);
  }

  // -------------------------------------------------------------------------

  addDefTuple(List<ASTNode> members, ASTNode rhs) {
    PtlsTuple func() {
      PtlsTuple tuple = evalCheck(this, rhs, [PtlsTuple]);
      return tuple.checkLength(members.length);
    } 

    var tupleThunk = Thunk("", func);
    var index = 0;

    for (ASTNode memberNode in members) {
      String name = memberNode[0];

      // capture current index in closure
      var ind = index;
      var func = () => tupleThunk.getValue().getMember(ind);
      var thunk = Thunk(name, func);

      addDefThunk(thunk);
      index++;
    }
  }

  // -------------------------------------------------------------------------

  PtlsValue lookupName(String name) {
    var searchEnv = this;

    while (searchEnv != null) {
      if (searchEnv.defs.containsKey(name)) {
        return searchEnv.defs[name].getValue();
      }

      searchEnv = searchEnv.parent;
    }

    var error = PtlsError("Name Error");
    error.message = "No definition for name '$name'";
    throw error;
  }

  // -------------------------------------------------------------------------

  Iterable<dynamic> getOutput() sync* {
    if (!defs.containsKey("output")) {
      var error = PtlsError("Name Error");
      error.message = "Source root missing 'output' definition";
      throw error;
    }

    var output = lookupName("output").checkIsList();

    while (output is PtlsList) {
      yield (output as PtlsList).head;
      output = (output as PtlsList).tail;
    }
  }
}
