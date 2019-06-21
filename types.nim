import nimline
import os
import macros

const
  cwd = currentSourcePath.parentDir()
  include_path = cwd / "libtorch" / "include"
  lib_path = cwd / "libtorch" / "lib"
  torch_header* = "<torch/script.h>"

nimline.cppdefines("_GLIBCXX_USE_CXX11_ABI=0")
nimline.cppincludes($include_path)
nimline.cpplibpaths($lib_path)
nimline.cpplibs("torch")
nimline.cpplibs("caffe2")
nimline.cpplibs("c10")

defineCppType(Module, "torch::jit::script::Module", $torch_header)

type
  ModulePtr* {.importcpp: "std::shared_ptr<torch::jit::script::Module>", header: torch_header.} = object

macro invokeArrow*(obj: CppObject, field: untyped, args: varargs[CppProxy, cppFromAst]): CppProxy =
  ## Calls a mathod of a C++ object with `args` as arguments and returns a CppProxy.
  ## Return values have to be converted using `to(T)` or used in other C++ calls.
  ## Void returns have to be explicitly discarded with `to(void)`.
  var importString: string
  if obj.len == 0 and $obj == "global":
    importString = $field & "(@)"
    
    result = quote:
      proc helper(): CppProxy {.importcpp:`importString`, gensym.}
      helper()
  else:
    when defined(js):
      importString = "#." & "_" & $field & "(@)"
    else:
      importString = "#->" & $field & "(@)"
    
    result = quote:
      proc helper(o: CppObject): CppProxy {.importcpp:`importString`, gensym.}
      helper(`obj`)
  
  for idx in 0 ..< args.len:
    let paramName = ident("param" & $idx)
    result[0][3].add newIdentDefs(paramName, ident("CppProxy"))
    result[1].add args[idx].copyNimTree