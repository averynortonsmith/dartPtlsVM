
import "dart:math";

import "vm.dart";

// -----------------------------------------------------------------------------

class VM with Stack, EnvStack {

  var index = 0;
  List<Instruction> insts;
  List<PtlsObject> imports;

  // ---------------------------------------------------------------------------

  VM(this.insts, int numImports) {
    imports = List(numImports);
  }

  // ---------------------------------------------------------------------------

  Instruction get inst => insts[index];

  // ---------------------------------------------------------------------------

  static void getOutput(SourceFile source) {
    var compiler = Compiler();
    compiler.compileRoot(source);

    var numImports = compiler.importCache.length;
    var vm = VM(compiler.insts, numImports);
    vm.exec(); // .forEach(print);
  }

  // ---------------------------------------------------------------------------

  void exec() {
    for (;;) {

      // print(inst);

      switch (inst.op) {

        case Op.Add:
          var lhs = popCheck([PtlsNumber, PtlsString]);

          if (lhs is PtlsNumber) {
            PtlsNumber rhs = popCheck([PtlsNumber]);
            pushValue(PtlsNumber(lhs.value + rhs.value));

          } else if (lhs is PtlsString) {
            PtlsString rhs = popCheck([PtlsString]);
            pushValue(PtlsString(lhs.value + rhs.value));
          }

          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.And:
          PtlsBool lhs = popCheck([PtlsBool]);
          if (!lhs.value) {
            pushValue(lhs);
            index++;
            break;
          }

          // skip jump instruction
          index += 2;
          break;

        // ---------------------------------------------------------------------

        case Op.Call:
          var func = popCheck([PtlsFunc, PtlsBuiltIn, PtlsLabel]);
          var args = [for (var i = 0; i < inst.arg; i++) popValue()];

          if (func is PtlsFunc) {
            var newEnv = func.env.clone();
            var paramIndex = func.paramIndex;

            for (var arg in args.reversed) {
              // func params don't get names, since env will never be
              // accessed in field ref
              newEnv.addDef(Def.fromValue(arg, ""), paramIndex++);
            }

            if (paramIndex < func.arity) {
              pushValue(PtlsFunc(newEnv, func.instInd, paramIndex, func.arity));
              index++;
              break;
            }

            if (insts[index + 1].op == Op.Return) {
              var retInd = popReturn();
              pushEnv(newEnv, retInd);

            } else {
              pushEnv(newEnv, index + 1);
            }

            index = func.instInd;
            break;
          }

          throw false;

        // ---------------------------------------------------------------------

        case Op.CheckBool:
          checkTOS([PtlsBool]);
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Clone:
          throw false;

        // ---------------------------------------------------------------------

        case Op.CloneField:
          throw false;

        // ---------------------------------------------------------------------

        case Op.CloneIndex:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Concat:
          var value = getTOS().checkIsList();
          if (value.isEmpty) {
            // leave Empty on stack for SaveTail
            // will return to jump past rhs code
            pushEnv(currentEnv, index + 1);
            index += 2; // enter rhs code
            break;
          }

          PtlsList list = popCheck([PtlsList]);
          var thunk = Thunk(currentEnv, index + 2);
          pushValue(list.concat(thunk));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Destructure:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Dispatch:
          if (getTOS().isEmpty) {
            return;
          }

          PtlsList list = checkTOS([PtlsList]);
          if (list.headThunk.hasValue) {
            print(list.headThunk.value);
            popValue(); // pop list off stack

            if (list.tailThunk.hasValue) {
              pushValue(list.tailThunk.value);
              // same index to stay on Dispatch
              break;

            } else {
              // push Empty move to tail on SaveTail
              pushValue(PtlsLabel.empty);
              pushEnv(list.tailThunk.env, index);
              index = list.tailThunk.instInd;
              break;
            }
          }

          // list is still on stack
          pushEnv(list.headThunk.env, index);
          index = list.headThunk.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.Div:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsNumber(lhs.value / rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Dup:
          pushValue(getTOS());
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Equals:
          var lhs = popValue();
          var rhs = popValue();
          pushValue(PtlsBool(lhs == rhs));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.FieldRef:
          PtlsObject object = popCheck([PtlsObject]);
          var def = object.env.lookupName(inst.arg);

          if (def == null || (!object.env.exportAll && !def.exported)) {
            var error = PtlsError("Name Error");
            error.message = "No definition for name '${inst.arg}'";
            throw error;
          }

          if (def.hasValue) {
            pushValue(def.value);
            index++;
            break;
          }

          pushEnv(object.env, index + 1);
          index = def.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.GetAddElem:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetDelElem:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetDelKey:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetDict:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetFloat:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetHead:
          PtlsList list = checkTOS([PtlsList]);
          if (list.headThunk.hasValue) {
            popValue(); // pop list off stack
            pushValue(list.headThunk.value);
            index++;
            break;
          }

          // list is still on stack
          pushEnv(list.headThunk.env, index);
          index = list.headThunk.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.GetInt:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetKeys:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetLabel:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetLength:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetLines:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetList:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetRand:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetSet:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetString:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetTail:
          PtlsList list = checkTOS([PtlsList]);
          if (list.tailThunk.hasValue) {
            popValue(); // pop list off stack
            pushValue(list.tailThunk.value);
            index++;
            break;
          }

          // list is still on stack
          pushEnv(list.tailThunk.env, index);
          index = list.tailThunk.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.GetType:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetVals:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GetZeros:
          throw false;

        // ---------------------------------------------------------------------

        case Op.GreaterEq:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsBool(lhs.value >= rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.GreaterThan:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsBool(lhs.value > rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.In:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Index:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Jump:
          index += inst.arg;
          break;

        // ---------------------------------------------------------------------

        case Op.JumpIfFalse:
          PtlsBool pred = popCheck([PtlsBool]);
          index += !pred.value ? inst.arg : 1;
          break;

        // ---------------------------------------------------------------------

        case Op.LessEq:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsBool(lhs.value <= rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.LessThan:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsBool(lhs.value < rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadBool:
          pushValue(PtlsBool.loadBool(inst.arg));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadGlobal:
          var def = currentGlobals.defs[inst.arg];

          if (def.hasValue) {
            pushValue(def.value);
            index++;
            break;
          }

          def.checkLock();

          // need to evaluate def insts in original env
          // load commands should have code at end of def block to save
          // value back to original env
          // (don't need to ues def.originalEnv for globals and prelude,
          // since these defs are never copied for upvals)
          pushEnv(currentGlobals, index + 1);
          def.lock = true;
          index = def.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadImport:
          // imports should have already been allocated by saveImports
          pushValue(imports[inst.arg]);
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadLocal:
          var def = currentEnv.defs[inst.arg];

          if (def.hasValue) {
            pushValue(def.value);
            index++;
            break;
          }

          def.checkLock();

          // (see corresponding comments for LoadGlobal)
          // need to eval def in original env for SaveVal
          // (def might have been copied into current env as upval)
          pushEnv(def.originalEnv, index + 1);
          def.lock = true;
          index = def.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadPrelude:
          var def = prelude.defs[inst.arg];

          if (def.hasValue) {
            pushValue(def.value);
            index++;
            break;
          }

          def.checkLock();

          // (see corresponding comments for LoadGlobal)
          pushEnv(prelude, index + 1);
          def.lock = true;
          index = def.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.LoadStr:
          pushValue(PtlsString(inst.arg));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeArray:
          throw false;

        // ---------------------------------------------------------------------

        case Op.MakeCons:
          var headThunk = Thunk(currentEnv, index + 3);
          var tailThunk = Thunk(currentEnv, index + 2);
          pushValue(PtlsList(headThunk, tailThunk));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeDef:
          int defInd = inst.arg[0];
          String name = inst.arg[1];
          currentEnv.addDef(Def(index + 2, name), defInd);
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeDict:
          throw false;

        // ---------------------------------------------------------------------

        case Op.MakeEnv:
          // these envs should always be pop'd, not returned
          pushEnv(makeEnv(inst.arg), null);
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeFunc:
          pushValue(PtlsFunc(currentEnv, index + 2, 0, inst.arg));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeLabel:
          pushValue(PtlsLabel(inst.arg));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeNumber:
          pushValue(PtlsNumber(inst.arg));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeObject:
          pushValue(PtlsObject(currentEnv));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.MakeSet:
          throw false;

        // ---------------------------------------------------------------------

        case Op.MakeTuple:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Mod:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsNumber(lhs.value % rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Mul:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsNumber(lhs.value * rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Neg:
          throw false;

        // ---------------------------------------------------------------------

        case Op.Not:
          throw false;

        // ---------------------------------------------------------------------

        case Op.NotEq:
          var lhs = popValue();
          var rhs = popValue();
          pushValue(PtlsBool(lhs != rhs));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Or:
          PtlsBool lhs = popCheck([PtlsBool]);
          if (lhs.value) {
            pushValue(lhs);
            index++;
            break;
          }

          // skip jump instruction
          index += 2;
          break;

        // ---------------------------------------------------------------------

        case Op.Panic:
          PtlsString message = popCheck([PtlsString]);
          var error = PtlsError("Panic Error");
          error.message = message.value;
          throw error;

        // ---------------------------------------------------------------------

        case Op.Pop:
          popValue();
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.PopEnv:
          popEnv();
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Pow:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsNumber(pow(lhs.value, rhs.value)));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.PushHandler:
          throw false;

        // ---------------------------------------------------------------------

        case Op.ResolveList:
          getTOS().checkIsList();

          if (getTOS().isEmpty) {
            popValue();
            index++;
            break;
          }

          PtlsList list = checkTOS([PtlsList]);
          if (list.tailThunk.hasValue) {
            popValue(); // replace current list with tail
            pushValue(list.tailThunk.value);
            // re-run same instruction to keep un-rolling list
            break;
          }

          // will enter above condition on next invocation
          // keep list on stack for SaveTail
          pushEnv(list.tailThunk.env, index);
          index = list.tailThunk.instInd;
          break;

        // ---------------------------------------------------------------------

        case Op.Return:
          index = popReturn();
          break;

        // ---------------------------------------------------------------------

        case Op.SaveExport:
          currentEnv.exportAll = false;
          currentEnv.defs[inst.arg].exported = true;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SaveHead:
          var value = popValue();
          PtlsList list = checkTOS([PtlsList]);
          list.headThunk.value = value;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SaveImport:
          PtlsObject object = popCheck([PtlsObject]);
          imports[inst.arg] = object;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SavePrelude:
          PtlsObject object = popCheck([PtlsObject]);
          prelude = object.env;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SaveTail:
          var value = popValue().checkIsList();
          if (getTOS().isEmpty) {
            popValue();
            pushValue(value); // tail is entire list when lhs is Empty
            index++;
            break;
          }

          PtlsList list = checkTOS([PtlsList]);
          list.tailThunk.value = value;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SaveVal:
          var def = currentEnv.defs[inst.arg];
          def.value = getTOS();
          def.lock = false;
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.SaveUpval:
          int defInd = inst.arg[0];
          int upInd = inst.arg[1];
          currentEnv.addDef(parentEnv.defs[upInd], defInd);
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Sub:
          PtlsNumber lhs = popCheck([PtlsNumber]);
          PtlsNumber rhs = popCheck([PtlsNumber]);
          pushValue(PtlsNumber(lhs.value - rhs.value));
          index++;
          break;

        // ---------------------------------------------------------------------

        case Op.Throw:
          throw false;

        // ---------------------------------------------------------------------

        case Op.UpdateField:
          throw false;

        // ---------------------------------------------------------------------

        case Op.UpdateIndex:
          throw false;
      }
    }
  }
}
