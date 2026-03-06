const asyncBackend {.strdefine.} = ""

when asyncBackend == "chronos":
  import chronos
  export chronos
elif defined(js):
  import std/asyncjs
  export asyncjs
else:
  import std/asyncdispatch
  export asyncdispatch
