
import "package:dartz/dartz.dart" as dartz;

import "interpreter.dart";

// ---------------------------------------------------------------------------

var depth = 0;

PtlsValue eval(Env env, ASTNode node) {
  var maxDepth = 1000;

  if (depth > maxDepth) {
    var error = PtlsError("Recursion Error");
    error.message = "Max call depth ($maxDepth) exceeded";
    throw error;
  }

  PtlsValue result;

  try {
    depth++;
    result = dispatch(env, node);
    depth--;

  } on PtlsError catch(error) {
    error.locs.add(node.loc);
    rethrow;
  }

  return result;
}

// ---------------------------------------------------------------------------

PtlsValue evalCheck(Env env, ASTNode node, List<Type> types) {
  return eval(env, node).checkType(types);
}

// ---------------------------------------------------------------------------

PtlsValue dispatch(Env env, ASTNode node) {
  // trampoline to allow for tail-call optimization
  for (;;) {
    
    switch (node.nodeType) {

      case Node.Array:
        var elems = [for (var elemNode in node[0]) eval(env, elemNode)];
        return PtlsArray(dartz.IVector.from(elems));

      // ---------------------------------------------------------------------

      case Node.BinaryOp:
        // (op, lhsNode, rhsNode)
        return handleBinaryOp(env, node[0], node[1], node[2]);

      // ---------------------------------------------------------------------

      case Node.Bool:
        return PtlsBool(node[0]);

      // ---------------------------------------------------------------------

      case Node.Call:
        var func = evalCheck(env, node[0], [PtlsBuiltIn, PtlsFunc, PtlsLabel]);

        var args = [for (var argNode in node[1]) eval(env, argNode)];

        if (func is PtlsFunc) {
          var newEnv = func.env.clone();

          for (var arg in args) {
            var name = func.params[newEnv.defs.length];
            var thunk = Thunk.fromValue(name, arg);
            newEnv.addDefThunk(thunk);
          }

          if (newEnv.defs.length < func.params.length) {
            return PtlsFunc(newEnv, func.params, func.body);
          }

          env = newEnv;
          node = func.body;
          continue;
        }

        if (func is PtlsLabel) {
          return PtlsTuple(func, args);
        }

        if (func is PtlsBuiltIn) {
          if (args.length != 1) {
            var error = PtlsError("Type Error");
            error.message = "Invalid arg count ${args.length}";
            error.message += " for built-in method ${func.signature}";
            throw error;
          }

          return func.handler(args[0]);
        }

        throw false;

      // ---------------------------------------------------------------------

      case Node.Conditional:
        PtlsBool pred = evalCheck(env, node[0], [PtlsBool]);

        if (pred.value) {
          node = node[1]; // then
          continue;
        }

        node = node[2]; // else
        continue;

      // ---------------------------------------------------------------------

      case Node.Dict:
        var map = dartz.IHashMap<PtlsValue, PtlsValue>.from({
          for (ASTNode pair in node[0])
          eval(env, pair[0]): eval(env, pair[1])
        });

        return PtlsDict(map);

      // ---------------------------------------------------------------------

      case Node.FieldRef:
        var lhs = eval(env, node[0]);
        String name = (node[1] as ASTNode)[0];
        return lhs.getField(name);

      // ---------------------------------------------------------------------

      case Node.Func:
        // (env, params, body)
        List<String> params = [for (var paramNode in node[0]) paramNode[0]];
        return PtlsFunc(env.spawn(), params, node[1]);

      // ---------------------------------------------------------------------

      case Node.Import:
        var source = SourceFile.loadImport(node);
        return PtlsObject(Env.loadEnv(source));

      // ---------------------------------------------------------------------

      case Node.Index:
        var lhs = eval(env, node[0]);
        var rhs = eval(env, node[1]);
        return lhs.getIndex(rhs);

      // ---------------------------------------------------------------------

      case Node.Label:
        return PtlsLabel(node[0]);

      // ---------------------------------------------------------------------

      case Node.List:
        PtlsValue result = PtlsLabel("Empty");

        for (var elemNode in node[0].reversed) {
          // capture current elemNode and result in closure
          var el = elemNode;
          var res = result;
          var headThunk = Thunk("", () => eval(env, el));
          var tailThunk = Thunk("", () => res);
          result = PtlsList(headThunk, tailThunk);
        }

        return result;

      // ---------------------------------------------------------------------

      case Node.Name:
        return env.lookupName(node[0]);

      // ---------------------------------------------------------------------

      case Node.Number:
        return PtlsNumber(node[0]);

      // ---------------------------------------------------------------------

      case Node.Object:
        var newEnv = env.spawn();

        for (ASTNode defNode in node[0]) {
          newEnv.addDef(defNode);
        }

        return PtlsObject(newEnv);

      // ---------------------------------------------------------------------

      case Node.Panic:
        PtlsString message = evalCheck(env, node[0], [PtlsString]);

        var error = PtlsError("Panic");
        error.message = message.value;
        throw error;

      // ---------------------------------------------------------------------

      case Node.Program:
        ASTNode export = node[0];
        List<ASTNode> imports = node[1];
        List<ASTNode> defs = node[2];

        for (ASTNode importNode in imports) {
          String name = (importNode[1] as ASTNode)[0];
          var thunk = Thunk(name, () => eval(env, importNode));
          env.addDefThunk(thunk);
        }

        for (ASTNode defNode in defs) {
          env.addDef(defNode);
        }

        if (export != null) {
          // thunks eval in original scope, so no parent scope is needed
          var newEnv = Env(null);

          for (ASTNode nameNode in export[0]) {
            String name = nameNode[0];
            var thunk = Thunk(name, () => env.lookupName(nameNode[0]));
            newEnv.addDefThunk(thunk);
          }

          return PtlsObject(newEnv);
        }

        return PtlsObject(env);

      // ---------------------------------------------------------------------

      case Node.Set:
        var map = dartz.IHashMap<PtlsValue, PtlsValue>.from({
          for (ASTNode elemNode in node[0])
          eval(env, elemNode): null
        });

        return PtlsSet(map);

      // ---------------------------------------------------------------------

      case Node.String:
        return PtlsString(node[0]);

      // ---------------------------------------------------------------------

      case Node.Throw:
        var value = eval(env, node[0]); // body
        throw PtlsException(value, node.loc);

      // ---------------------------------------------------------------------

      case Node.Try:
        try {
          return eval(env, node[0]);

        } on PtlsException catch (exc) {
          var valNode = ASTNode(Node.RuntimeValue, null, [exc.value]);
          var funcNode = node[1];
          var callNode = ASTNode(Node.Call, node.loc, [funcNode, [valNode]]);
          node = callNode;
          continue;
        }

        // should never get here
        throw false;

      // ---------------------------------------------------------------------

      case Node.Tuple:
        var members = [for (var memNode in node[0]) eval(env, memNode)];
        return PtlsTuple(PtlsTuple.defaultLabel, members);

      // ---------------------------------------------------------------------

      case Node.UnaryOp:
        // (op, operandNode)
        return handleUnaryOp(env, node[0], node[1]);

      // ---------------------------------------------------------------------

      case Node.Where:
        PtlsObject obj = eval(env, node[1]);
        env = obj.env;
        node = node[0]; // body
        continue;

      // ---------------------------------------------------------------------

      case Node.With:
        var lhs = evalCheck(env, node[0], [PtlsDict, PtlsObject, PtlsArray]);

        var newEnv = env.clone();
        var thunk = Thunk.fromValue("\$", lhs);
        newEnv.addDefThunk(thunk);

        // def rhs values
        var values = [for (ASTNode def in node[1]) eval(env, def[1])];
        var index = 0;

        for (ASTNode def in node[1]) {
          thunk.value = PtlsValue.update(newEnv, def[0], values[index++]);
        }

        return thunk.value;

      // ---------------------------------------------------------------------
      // used for making "value nodes" for internal interpreter use
      // (see case Node.Try)

      case Node.RuntimeValue:
        return node[0];

      // ---------------------------------------------------------------------
      // should be handled by other handlers

      case Node.Pair:   throw false;
      case Node.Blank:  throw false;
      case Node.Def:    throw false;
      case Node.Export: throw false;

    }
  }
}
