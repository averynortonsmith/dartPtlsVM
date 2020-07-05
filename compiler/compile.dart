
import "dart:collection";

import "compiler.dart";

// -----------------------------------------------------------------------------

class Compiler {
  ASTNode currentNode;
  List<Instruction> insts = [];

  // ---------------------------------------------------------------------------

  int get index => insts.length;

  // ---------------------------------------------------------------------------

  Instruction addInst(Instruction inst) {
    inst.index = index;
    inst.loc = currentNode.loc;
    insts.add(inst);
    return inst;
  }

  // ---------------------------------------------------------------------------
  // set jump (relative index) to jump to next instruction index
  // takes index of jump instruction to update
  // (many compiler routines generate a jump inst then set its argument
  // once the instructions to jump past have been generated)

  void setJump(Instruction inst) {
    inst.arg = index - inst.index; 
    inst.hint = "-> $index";
  }

  // ---------------------------------------------------------------------------
  // example compiler output in comments may be outdated / inaccurate

  // ---------------------------------------------------------------------------
  // convert chained jumps a -> b, b -> c to a -> c, b -> c
  // 
  // convert each jump instruction in a series of jumps which leads to a 
  // return instruction to return instructions
  //
  // makes code more efficient, but more imporantly it allows the vm
  // to detect tail-calls in structures like conditional
  //
  // example: foo(n) = if n == 0 then "zero" else "non-zero"
  //
  // 17 [ Equals       ]
  // 18 [ JumpIfFalse  ] 3       
  // 19 [ LoadStr      ] 6       ("zero")
  // 20 [ Jump         ] 2       (-> 22)
  // 21 [ LoadStr      ] 11      ("non-zero")
  // 22 [ Return       ]
  //
  // becomes: 
  //
  // 17 [ Equals       ]
  // 18 [ JumpIfFalse  ] 3       
  // 19 [ LoadStr      ] 6       ("zero")
  // 20 [ Return       ]
  // 21 [ LoadStr      ] 11      ("non-zero")
  // 22 [ Return       ]

  void convertJumps() {
    // go in reverse so that conversion is propagted back up sequences
    // of jumps (all jump instructions should be forward jumps except for
    // jumps to import defs, which won't be important to convert for tco)
    for (var inst in insts.reversed) {
      if (inst.op != Op.Jump) {
        continue;
      }

      int jumpInd = inst.index + inst.arg;
      if (jumpInd == index) {
        continue;
      }

      if (insts[jumpInd].op == Op.Return) {
        inst.op = Op.Return;
        inst.arg = null;
        inst.hint = null;

      } else if (insts[jumpInd].op == Op.Jump) {
        // point jump to index of downstream jump
        inst.arg += insts[jumpInd].arg;
        
        // jump now points to same absolute index as downstream jump
        inst.hint = insts[jumpInd].hint;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LinkedHashSet for in-order iteration
  var importCache = LinkedHashSet<SourceFile>();

  void getImports(SourceFile source) {
    if (importCache.contains(source)) {
      return;
    }

    source.index = importCache.length;
    importCache.add(source);

    var node = source.getNode();
    List<ASTNode> imports = node[1];

    for (var importNode in imports) {
      var file = SourceFile.loadImport(importNode);
      getImports(file);
    }
  }

  // ---------------------------------------------------------------------------

  void compileSource(SourceFile source) {
    source.getScope(); // annotate source
    compileNode(source.getNode());
    convertJumps();
  }

  // ---------------------------------------------------------------------------

  void compileRoot(SourceFile source) {
    compileSource(SourceFile.prelude);
    addInst(Instruction(Op.SavePrelude));

    // prelude cannot contain imports
    getImports(source);

    for (var importSource in importCache) {
      compileSource(importSource);
      addInst(Instruction(Op.SaveImport, importSource.index));
    }

    // load source root object
    addInst(Instruction(Op.LoadImport, 0));
    // source root must export output field
    addInst(Instruction(Op.FieldRef, "output"));
    addInst(Instruction(Op.Dispatch));
  }

  // ---------------------------------------------------------------------------
  // for a node that introduces a scope, generate instructions
  // make the scope and save upvalues as from parent as needed
  //
  // example: captures local at index 0 to env with 1 local, 1 upvalue
  // 7 [ LoadLocal    ] 0       
  // 8 [ MakeEnv      ] 2       
  // 9 [ SaveVal      ] 1

  void compileEnv(LexScope scope) {
    addInst(Instruction(Op.MakeEnv, scope.entries.length));

    for (var entry in scope.entries.values) {
      // prelude has null'd entries
      if (entry?.upIndex != null) {
        // should never be global or prelude, since those don't get captured
        addInst(Instruction(Op.SaveUpval, [entry.index, entry.upIndex]));
      }
    }
  }

  // ---------------------------------------------------------------------------

  void compileArray(List<ASTNode> elems) {
    elems.forEach(compileNode);
    addInst(Instruction(Op.MakeArray, elems.length));
  }

  // ---------------------------------------------------------------------------

  static var opsMap = {
    Tok.Add: Op.Add,
    Tok.Div: Op.Div,
    Tok.Equals: Op.Equals,
    Tok.GreaterEq: Op.GreaterEq,
    Tok.GreaterThan: Op.GreaterThan,
    Tok.In: Op.In,
    Tok.LessEq: Op.LessEq,
    Tok.LessThan: Op.LessThan,
    Tok.Mod: Op.Mod,
    Tok.Mul: Op.Mul,
    Tok.NotEq: Op.NotEq,
    Tok.Pow: Op.Pow,
    Tok.Sub: Op.Sub,
  };

  void compileBinaryOp(Tok op, ASTNode lhs, ASTNode rhs) {
    // concat handled as special case to eval lhs list
    if (op == Tok.Concat) {
      compileNode(lhs);
      // make duplicate for resolveList to process
      addInst(Instruction(Op.Dup));

      // evaluate all entries in dup list (list should be finite for concat)
      // (eval updates values in the original list as well)
      addInst(Instruction(Op.ResolveList));

      addInst(Instruction(Op.Concat));
      var jump = addInst(Instruction(Op.Jump));

      compileNode(rhs);
      addInst(Instruction(Op.SaveTail));
      addInst(Instruction(Op.Return));
      setJump(jump);

    } else if (op == Tok.And || op == Tok.Or) {
      compileNode(lhs);
      // handle these ops separately to accomodate short circuit eval
      addInst(Instruction(op == Tok.And ? Op.And : Op.Or));

      // jump past operand instructions to avoid executing right away
      var jump = addInst(Instruction(Op.Jump));

      // op will save this index (second after Op_Concat inst)
      compileNode(rhs);
      addInst(Instruction(Op.CheckBool));
      setJump(jump); // don't need return, unlike concat

    } else {
      // compile in reverse to pop in normal order
      compileNode(rhs);
      compileNode(lhs);
      addInst(Instruction(opsMap[op]));
    }
  }

  // ---------------------------------------------------------------------------

  void compileBool(bool value) {
    addInst(Instruction(Op.LoadBool, value));
  }

  // ---------------------------------------------------------------------------

  void compileCall(ASTNode func, List<ASTNode> args) {
    args.forEach(compileNode);
    compileNode(func);
    addInst(Instruction(Op.Call, args.length));
  }

  // ---------------------------------------------------------------------------

  void compileConditional(ASTNode cond, ASTNode thenNode, ASTNode elseNode) {
    compileNode(cond);
    var elseJump = addInst(Instruction(Op.JumpIfFalse));

    compileNode(thenNode);
    var endJump = addInst(Instruction(Op.Jump));

    setJump(elseJump);
    compileNode(elseNode);

    setJump(endJump);
  }

  // ---------------------------------------------------------------------------

  void compileDefHelper(ASTNode nameNode, Function defFunc) {
    String name = nameNode[0];
    addInst(Instruction(Op.MakeDef, [nameNode.index, name]));

    // jump over def instructions
    var jump = addInst(Instruction(Op.Jump));

    // makeDef will save this index (second after Op_MakeDef inst)
    // as inst to jump to when evaluating def
    defFunc();

    // SaveVal stores the computed value in the env
    // thus each def only has its value computed once
    addInst(Instruction(Op.SaveVal, nameNode.index, name));

    // when var lookup triggers evaluation, have to return back to calling
    // instruction afterwards - var lookup inst gets re-run, but this time
    // (new env is generated for eval upon lookup)
    // the def entry will have the value computed - should not trigger re-eval
    addInst(Instruction(Op.Return));

    // jump past def instructions to avoid immediate evaluation
    setJump(jump);
  }

  // ---------------------------------------------------------------------------
  // example: x = 123
  //
  // 0 [ MakeNumber   ] 0      
  // 1 [ MakeDef      ] 0       (x)
  // 2 [ Jump         ] 4       (-> 6)
  // 3 [ MakeNumber   ] 123    
  // 4 [ SaveVal      ] 0       (x)
  // 5 [ Return       ]

  void compileNameDef(ASTNode nameNode, ASTNode rhs) {
    compileDefHelper(nameNode, () => compileNode(rhs));
  }

  // ---------------------------------------------------------------------------
  // all names in tuple def get daisy-chained together through jumps, all
  // jump to the same instruction upon name lookup - eval of any name results
  // in eval and storage of all names in tuple def at once
  // daisy-chained jumps get converted to single jumps in convertJumps
  //
  // example: (a, b, c) = x
  //
  // 10 [ MakeNumber   ] 13      
  // 11 [ MakeDef      ] 1       (a)
  // 12 [ Jump         ] 2       (-> 14)
  // 13 [ Jump         ] 4       (-> 17)
  // 14 [ MakeNumber   ] 15      
  // 15 [ MakeDef      ] 2       (b)
  // 16 [ Jump         ] 2       (-> 18)
  // 17 [ Jump         ] 4       (-> 21)
  // 18 [ MakeNumber   ] 17      
  // 19 [ MakeDef      ] 3       (c)
  // 20 [ Jump         ] 7       (-> 27)
  // 21 [ LoadGlobal   ] 4       (x)
  // 22 [ Destructure  ] 3       
  // 23 [ SaveVal      ] 1       ()
  // 24 [ SaveVal      ] 2       ()
  // 25 [ SaveVal      ] 3       ()
  // 26 [ Return       ]
  //
  // example: (a, _, c) = x
  //
  // 10 [ MakeNumber   ] 13      
  // 11 [ MakeDef      ] 1       (a)
  // 12 [ Jump         ] 2       (-> 14)
  // 13 [ Jump         ] 4       (-> 17)
  // 18 [ MakeNumber   ] 15      
  // 19 [ MakeDef      ] 2       (c)
  // 20 [ Jump         ] 7       (-> 27)
  // 21 [ LoadGlobal   ] 3       (x)
  // 22 [ Destructure  ] 3       
  // 23 [ SaveVal      ] 1       ()
  // 24 [ Pop          ] 1       
  // 25 [ SaveVal      ] 2       ()
  // 26 [ Return       ]

  void compileTupleDefs(List<ASTNode> members) {
    for (var member in members) {
      if (member.nodeType == Node.Blank) {
        continue;
      }

      // make def entries for each name member
      String name = member[0];
      addInst(Instruction(Op.MakeDef, [member.index, name]));

      if (member != members.last) {
        // if this isn't the last name member, daisy-chain jumps:
        // for definition, jump to next name definition
        addInst(Instruction(Op.Jump, 2, "-> ${index + 2}"));

        // for evaluation, jump to eval inst of next member until the
        // instructions for all members is reached (in the def the last name)
        addInst(Instruction(Op.Jump, 4, "-> ${index + 4}"));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // make instructions to pull out values of each tuple member an save in
  // corresponding name defs

  void compileTupleSaves(List<ASTNode> members) {
    addInst(Instruction(Op.Destructure, members.length));

    for (var member in members) {
      if (member.nodeType == Node.Blank) {
        addInst(Instruction(Op.Pop, 1));

      } else {
        String name = member[0];
        var nodeIndex = member.index;
        addInst(Instruction(Op.SaveVal, nodeIndex, name));
      }
    }
  }

  // ---------------------------------------------------------------------------

  void compileDef(ASTNode lhs, ASTNode rhs) {
    if (lhs.nodeType == Node.Name) {
      compileNameDef(lhs, rhs);

    } else if (lhs.nodeType == Node.Tuple) {
      compileTupleDefs(lhs[0]);

      // jump inst for final name definition
      var jump = addInst(Instruction(Op.Jump));

      // load all tuple members
      compileNode(rhs);
      // save all tuple members
      compileTupleSaves(lhs[0]);
      addInst(Instruction(Op.Return));

      setJump(jump);

    } else if (lhs.nodeType != Node.Blank) {
      // should never get here
      throw false;
    }
  }

  // ---------------------------------------------------------------------------

  void compileDict(List<ASTNode> pairs) {
    pairs.forEach(compileNode);
    addInst(Instruction(Op.MakeDict, pairs.length));
  }

  // ---------------------------------------------------------------------------

  void compileExport(List<ASTNode> nameNodes) {
    for (var nameNode in nameNodes) {
      String name = nameNode[0];
      addInst(Instruction(Op.SaveExport, nameNode.index, name));
    }
  }

  // ---------------------------------------------------------------------------

  static var langFieldsMap = {
    "!getAddElem": Op.GetAddElem,
    "!getDelElem": Op.GetDelElem,
    "!getDelKey": Op.GetDelKey,
    "!getDict": Op.GetDict,
    "!getFloat": Op.GetFloat,
    "!getHead": Op.GetHead,
    "!getInt": Op.GetInt,
    "!getKeys": Op.GetKeys,
    "!getLabel": Op.GetLabel,
    "!getLength": Op.GetLength,
    "!getLines": Op.GetLines,
    "!getList": Op.GetList,
    "!getRand": Op.GetRand,
    "!getSet": Op.GetSet,
    "!getString": Op.GetString,
    "!getTail": Op.GetTail,
    "!getType": Op.GetType,
    "!getVals": Op.GetVals,
    "!getZeros": Op.GetZeros,
  };

  void compileFieldRef(ASTNode obj, ASTNode field) {
    String name = field[0];
    compileNode(obj);

    if (name[0] == "!") {
      if (!langFieldsMap.containsKey(name)) {
        var error = PtlsError("Compiler Error");
        error.message = "Invalid built-in field '$name'";
        throw error;
      }

      addInst(Instruction(langFieldsMap[name]));

    } else {
      addInst(Instruction(Op.FieldRef, name));
    }
  }

  // ---------------------------------------------------------------------------

  void compileFunc(List<ASTNode> params, ASTNode body) {
    compileEnv(currentNode.scope);

    // func needs to know how many args to pop when it runs
    addInst(Instruction(Op.MakeFunc, params.length));

    // jump over func body to avoid immediate evaluation
    var jump = addInst(Instruction(Op.Jump));
    compileNode(body);
    // pop func env, return to instruction after calling instruction
    addInst(Instruction(Op.Return));

    setJump(jump);
    // after func is created, func loop env, return to original env
    // (don't use return inst, since we want to go on to the next inst)
    addInst(Instruction(Op.PopEnv));
  }

  // ---------------------------------------------------------------------------

  void compileImport(ASTNode pathNode, ASTNode nameNode) {
    var source = SourceFile.loadImport(currentNode);
    compileDefHelper(nameNode, () {
      // code for import generated in compileNodeProgram - saved at source.index
      // loadImport loads import object from given index (gets export if present)
      addInst(Instruction(Op.LoadImport, source.index));
    });
  }

  // ---------------------------------------------------------------------------

  void compileIndex(ASTNode lhs, ASTNode rhs) {
    compileNode(lhs);
    compileNode(rhs);
    addInst(Instruction(Op.Index));
  }

  // ---------------------------------------------------------------------------

  void compileLabel(String value) {
    addInst(Instruction(Op.MakeLabel, value));
  }

  // ---------------------------------------------------------------------------
  // example: x = [1, 2, 3]
  //
  //  9 [ MakeCons     ]
  // 10 [ Jump         ] 24      (-> 34)
  // 11 [ Jump         ] 4       (-> 15)
  // 12 [ MakeNumber   ] 1      
  // 13 [ SaveHead     ]
  // 14 [ Return       ]
  // 15 [ MakeCons     ]
  // 16 [ Jump         ] 16      (-> 32)
  // 17 [ Jump         ] 4       (-> 21)
  // 18 [ MakeNumber   ] 2      
  // 19 [ SaveHead     ]
  // 20 [ Return       ]
  // 21 [ MakeCons     ]
  // 22 [ Jump         ] 8       (-> 30)
  // 23 [ Jump         ] 4       (-> 27)
  // 24 [ MakeNumber   ] 3      
  // 25 [ SaveHead     ]
  // 26 [ Return       ]
  // 27 [ MakeLabel    ] 2       (Empty)
  // 28 [ SaveTail     ]
  // 29 [ Return       ]
  // 30 [ SaveTail     ]
  // 31 [ Return       ]
  // 32 [ SaveTail     ]
  // 33 [ Return       ]

  void compileTail(Iterator<ASTNode> elems) {
    if (!elems.moveNext()) {
      addInst(Instruction(Op.MakeLabel, "Empty"));
      return;
    }

    addInst(Instruction(Op.MakeCons));
    var endJump = addInst(Instruction(Op.Jump));
    var tailJump = addInst(Instruction(Op.Jump));

    compileNode(elems.current);

    addInst(Instruction(Op.SaveHead));
    addInst(Instruction(Op.Return));

    setJump(tailJump);

    compileTail(elems);

    addInst(Instruction(Op.SaveTail));
    addInst(Instruction(Op.Return));

    setJump(endJump);
  } 

  // ---------------------------------------------------------------------------

  void compileList(List<ASTNode> elems) {
    compileTail(elems.iterator);
  }

  // ---------------------------------------------------------------------------

  void compileName(String name) {
    var nodeIndex = currentNode.index;
    switch (currentNode.access) {
      case Level.Local:
        addInst(Instruction(Op.LoadLocal, nodeIndex, name));
        break;

      case Level.Global:
        addInst(Instruction(Op.LoadGlobal, nodeIndex, name));
        break;

      case Level.Prelude:
        addInst(Instruction(Op.LoadPrelude, nodeIndex, name));
        break;
    }
  }

  // ---------------------------------------------------------------------------

  void compileNumber(num value) {
    addInst(Instruction(Op.MakeNumber, value));
  }

  // ---------------------------------------------------------------------------

  void compileObject(List<ASTNode> defs) {
    compileEnv(currentNode.scope);
    defs.forEach(compileNode);
    addInst(Instruction(Op.MakeObject));
    addInst(Instruction(Op.PopEnv));
  }

  // ---------------------------------------------------------------------------

  void compilePair(ASTNode key, ASTNode val) {
    compileNode(key);
    compileNode(val);
  }

  // ---------------------------------------------------------------------------

  void compilePanic(ASTNode message) {
    compileNode(message);
    addInst(Instruction(Op.Panic));
  }

  // ---------------------------------------------------------------------------

  void compileProgram(ASTNode export, List<ASTNode> imports, List<ASTNode> defs) {
    compileEnv(currentNode.scope);
    imports.forEach(compileNode);
    defs.forEach(compileNode);

    // don't compile instructions for prelude exports
    // (handled statically by annotator)
    if (export != null && currentNode.scope.level != Level.Prelude) {
      compileNode(export);
    }

    addInst(Instruction(Op.MakeObject));
    addInst(Instruction(Op.PopEnv));
  }

  // ---------------------------------------------------------------------------

  void compileSet(List<ASTNode> elems) {
    elems.forEach(compileNode);
    addInst(Instruction(Op.MakeSet, elems.length));
  }

  // ---------------------------------------------------------------------------

  void compileString(String value) {
    addInst(Instruction(Op.LoadStr, value));
  }

  // ---------------------------------------------------------------------------

  void compileThrow(ASTNode error) {
    compileNode(error);
    addInst(Instruction(Op.Throw));
  }

  // ---------------------------------------------------------------------------

  void compileTry(ASTNode body, ASTNode handler) {
    addInst(Instruction(Op.PushHandler));
    var tryJump = addInst(Instruction(Op.Jump));

    compileNode(handler);

    addInst(Instruction(Op.Call)); // call handler
    var endJump = addInst(Instruction(Op.Jump));
    setJump(tryJump);

    compileNode(body);

    setJump(endJump);
  }

  // ---------------------------------------------------------------------------

  void compileTuple(List<ASTNode> members) {
    members.forEach(compileNode);
    addInst(Instruction(Op.MakeTuple, members.length));
  }

  // ---------------------------------------------------------------------------

  void compileUnaryOp(Tok op, ASTNode operand) {
    compileNode(operand);
    addInst(Instruction(op == Tok.Neg ? Op.Neg : Op.Not));
  }

  // ---------------------------------------------------------------------------

  void compileWhere(ASTNode body, ASTNode object) {
    compileEnv(currentNode.scope);

    object[0].forEach(compileNode); // defs

    compileNode(body);
    addInst(Instruction(Op.PopEnv));
  }

  // ---------------------------------------------------------------------------

  void compileCloneNested(ASTNode accessor) {
    // '$' base case
    if (accessor.nodeType == Node.Name) {
      return;
    }

    ASTNode lhs = accessor[0];
    // recursive call first for bottom-up clones
    compileCloneNested(lhs);

    if (accessor.nodeType == Node.Index) {
      compileNode(accessor[1]); // index node
      addInst(Instruction(Op.CloneIndex));

    } else {
      String field = accessor[1][0];
      addInst(Instruction(Op.CloneField, field));
    }
  }

  // ---------------------------------------------------------------------------

  void compileWithDef(ASTNode def) {
    ASTNode lhs = def[0];
    compileCloneNested(lhs[0]); // compile clones for lhs of lhs

    if (lhs.nodeType == Node.Index) {
      compileNode(lhs[1]); // index node
      addInst(Instruction(Op.UpdateIndex));

    } else {
      String field = lhs[1][0];
      addInst(Instruction(Op.UpdateField, field));
    }
  }

  // ---------------------------------------------------------------------------

  void compileWith(ASTNode lhs, List<ASTNode> defs) {
    compileNode(lhs);
    addInst(Instruction(Op.Clone));

    // could refactor this to work without using new env, but this is ok
    // make new env for updates - node should be annotated to make 1 def slot
    compileEnv(currentNode.scope);

    // save starting value in env
    // storing / updating working value in env makes things much simpler
    addInst(Instruction(Op.SaveVal, 0));

    // evaluate all rhs values before object is updated
    // allows for values being swapped (a with {$[0] = a[1]; $[1] = a[0]})
    // reverse to pop in order later
    for (var def in defs.reversed) {
      compileNode(def[1]); // compile rhs
    }

    defs.forEach(compileWithDef);

    // load updated value from env
    addInst(Instruction(Op.LoadLocal, 0));
    addInst(Instruction(Op.PopEnv));
  }

  // ---------------------------------------------------------------------------

  void compileNode(ASTNode node) {
    var oldNode = currentNode;
    currentNode = node;
    var handler = dispatch(node);
    Function.apply(handler, node.values);
    // keep program node as currentNode after program node is compiled
    // to get locations for subsequent dispatch insts
    currentNode = oldNode ?? currentNode;
  }

  // ---------------------------------------------------------------------------

  Function dispatch(ASTNode node) {
    switch (node.nodeType) {
      case Node.Array: return compileArray;
      case Node.BinaryOp: return compileBinaryOp;
      case Node.Bool: return compileBool;
      case Node.Call: return compileCall;
      case Node.Conditional: return compileConditional;
      case Node.Def: return compileDef;
      case Node.Dict: return compileDict;
      case Node.Export: return compileExport;
      case Node.FieldRef: return compileFieldRef;
      case Node.Func: return compileFunc;
      case Node.Import: return compileImport;
      case Node.Index: return compileIndex;
      case Node.Label: return compileLabel;
      case Node.List: return compileList;
      case Node.Name: return compileName;
      case Node.Number: return compileNumber;
      case Node.Object: return compileObject;
      case Node.Pair: return compilePair;
      case Node.Panic: return compilePanic;
      case Node.Program: return compileProgram;
      case Node.Set: return compileSet;
      case Node.String: return compileString;
      case Node.Throw: return compileThrow;
      case Node.Try: return compileTry;
      case Node.Tuple: return compileTuple;
      case Node.UnaryOp: return compileUnaryOp;
      case Node.Where: return compileWhere;
      case Node.With: return compileWith;

      default:
        // should never happen
        throw false;
    }
  }
}
