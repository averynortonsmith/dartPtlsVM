
import "../error/ptlsError.dart";
import "../parser/parser.dart";
import "../compiler/compiler.dart";
import "../interpreter/interpreter.dart" as interpreter;
import "../vm/vm.dart" as vm;

// ---------------------------------------------------------------------------

void runFlag(String path, String flag) {
  var source = SourceFile.loadPath(path, "");

  if (flag == "-tokenize") {
    source.getTokens().forEach(print);
    return;
  }

  if (flag == "-parse") {
    print(source.getNode());
    return;
  }

  if (flag == "-annotate") {
    source.getScope();
    showAnnotations(source.getNode());
    return;
  }

  if (flag == "-interpret") {
    var env = interpreter.Env.loadEnv(source);
    for (var command in env.getOutput()) {
      interpreter.runCommand(command);
    }
    return;
  }

  if (flag == "-compile") {
    var compiler = Compiler();
    compiler.getImports(source);
    compiler.compileSource(source);
    print(compiler.insts.join("\n"));
    return;
  }

  vm.VM.getOutput(source);
}

// ---------------------------------------------------------------------------

void runProgram(String path, String flag) {
  try {
    runFlag(path, flag);

  } on PtlsError catch(err) {
    print(err.toString());
  }
}

// ---------------------------------------------------------------------------

void main(List<String> args) {
  var flag = args.length > 1 ? args[1] : null;
  runProgram(args[0], flag);
}
