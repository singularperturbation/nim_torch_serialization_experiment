import os
import nimline
import types
#import torch/torch_cpp

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
  echo "LOADED MODEL"
  var model_name: StdString = unserialized_model.toCpp().invokeArrow("name")
  echo unserialized_model.repr

  echo "Model name: " & $model_name

  echo "Model is in training mode: " &
    $unserialized_model.toCpp().invokeArrow("is_training").to(bool)
  
  echo "Loaded model"


when isMainModule:
  main()
