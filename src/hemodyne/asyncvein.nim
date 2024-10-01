const asyncBackend {.strdefine.} = ""

when asyncBackend == "chronos":
  import chronos
else:
  import asyncdispatch

import stringresize

type AsyncVein* = object
  buffer*: string
  bufferLoader*: proc (): Future[string]
  freeBefore*: int

proc initAsyncVein*(buffer: string = "", loader: proc (): Future[string] = nil): AsyncVein {.inline.} =
  AsyncVein(buffer: buffer, bufferLoader: loader)

proc extendBufferOne*(r: var AsyncVein): Future[int] {.async.} =
  result = 0
  if not r.bufferLoader.isNil:
    {.cast(gcsafe), cast(raises: []).}:
      let ex = await r.bufferLoader()
    if ex.len == 0:
      r.bufferLoader = nil
    else:
      if r.buffer.smartResizeAdd(ex, r.freeBefore):
        result = r.freeBefore
        r.freeBefore = 0

proc extendBufferBy*(r: var AsyncVein, n: int): Future[int] {.async.} =
  result = 0
  var i = 0
  while not r.bufferLoader.isNil and i < n:
    {.cast(gcsafe), cast(raises: []).}:
      let ex = await r.bufferLoader()
    if ex.len == 0:
      r.bufferLoader = nil
    else:
      i += ex.len
      if r.buffer.smartResizeAdd(ex, r.freeBefore) and r.freeBefore != 0:
        result = r.freeBefore
        r.freeBefore = 0
