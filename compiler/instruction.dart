
import "compiler.dart";

// -----------------------------------------------------------------------------

class Instruction {
  Op op;
  int index;
  Location loc;
  dynamic arg;
  String hint;

  Instruction(this.op, [this.arg, this.hint]);

  String toString() {
    var indStr = index.toString().padLeft(4);
    var opStr = op.toString().split(".").last.padRight(12);
    var argStr = arg != null ? " $arg".padRight(24) : "";
    var hintStr = hint != null ? " ($hint)" : "";
    return "$indStr [ $opStr ]$argStr$hintStr";
  }
}
