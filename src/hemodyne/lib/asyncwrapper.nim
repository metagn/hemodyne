const asyncBackend {.strdefine.} = ""

when asyncBackend == "chronos":
  import chronos
  export chronos
elif defined(js):
  import std/asyncjs, asyncstreams
  export asyncjs, asyncstreams
else:
  import std/asyncdispatch, asyncstreams
  export asyncdispatch, asyncstreams
