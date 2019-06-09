import nimline
#import torch/torch_cpp

const cwd = staticExec("pwd")

nimline.cppdefines("_GLIBCXX_USE_CXX11_ABI=0")
nimline.cppincludes(cwd & "/libtorch/include/")
nimline.cpplibpaths(cwd & "/libtorch/lib")
nimline.cpplibs("torch")
nimline.cpplibs("caffe2")
nimline.cpplibs("c10")


const torch_header = "<torch/script.h>"

type
  # Doesn't seem to like ModulePtr = SharedPointer[Module], but maybe Module has
  # to be CppProxy type?
  Module {.importcpp: "torch::jit::script::Module", header: torch_header.} = object
  ModulePtr {.importcpp: "std::shared_ptr<torch::jit::script::Module>", header: "<memory>".} = object

# Was getting error with the converter in nimline where was producing:
#
# result = std::string(, nimToCStringConv(s)); // (extra comma)
#
# So had to make own dirty converter
converter myToStdString(s: string): nimline.StdString {.inline, noinit.} =
  {.emit: ["result = std::string(", s.cstring, ");"] .}

proc load(model_name: nimline.StdString): ModulePtr {.header: torch_header, importcpp: "torch::jit::load(@)" .}

proc main() =
  var model_file = "resnet_18.pt".myToStdString()

  var unserialized_model = load(model_file)

  echo "Loaded model"


when isMainModule:
  main()
