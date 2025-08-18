/**
 * @name Unsafe shell command execution
 * @description Detects potentially unsafe shell command execution that could lead to command injection
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.0
 * @precision high
 * @id lua/unsafe-shell-command
 * @tags security
 *       external/cwe/cwe-078
 */

import lua
import DataFlow::PathGraph

class UnsafeShellCommand extends TaintTracking::Configuration {
  UnsafeShellCommand() { this = "UnsafeShellCommand" }

  override predicate isSource(DataFlow::Node source) {
    // Sources from function parameters
    exists(Function f, int i |
      source.asParameter(i, f) and
      not f.getName().matches("^_")
    )
    or
    // Sources from file operations
    exists(FileSystemAccess fa | source.asExpr() = fa.getAPathString())
  }

  override predicate isSink(DataFlow::Node sink) {
    // os.execute sink
    exists(FunctionCall fc |
      fc.getTarget().(FunctionValue).getAPropertyRead().getAPrimaryQlClass() =
        OSModule::"os.execute" and
      fc.getAnArgument() = sink.asExpr()
    )
    or
    // io.popen sink
    exists(FunctionCall fc |
      fc.getTarget().(FunctionValue).getAPropertyRead().getAPrimaryQlClass() =
        IOModule::"io.popen" and
      fc.getAnArgument() = sink.asExpr()
    )
  }

  override predicate isSanitizer(DataFlow::Node node) {
    // Add common sanitization patterns
    exists(FunctionCall fc |
      fc.getTarget().toString() = "string.gsub" and
      fc.getAnArgument() = node.asExpr()
    )
  }
}

from DataFlow::PathNode source, DataFlow::PathNode sink, UnsafeShellCommand conf
where conf.hasFlowPath(source, sink)
select sink, source, sink,
  "Potentially unsafe shell command execution from $@.",
  source, "user input"
