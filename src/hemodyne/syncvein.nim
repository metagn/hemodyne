import stringresize

type Vein* = object
  buffer*: string
  bufferLoader*: proc (): string
  freeBefore*: int

proc initVein*(buffer: string = "", loader: proc (): string = nil): Vein {.inline.} =
  Vein(buffer: buffer, bufferLoader: loader)

proc extendBufferOne*(r: var Vein): int =
  result = 0
  if not r.bufferLoader.isNil:
    let ex = r.bufferLoader()
    if ex.len == 0:
      r.bufferLoader = nil
    else:
      if r.buffer.smartResizeAdd(ex, r.freeBefore):
        result = r.freeBefore
        r.freeBefore = 0

proc extendBufferBy*(r: var Vein, n: int): int =
  result = 0
  var i = 0
  while not r.bufferLoader.isNil and i < n:
    let ex = r.bufferLoader()
    if ex.len == 0:
      r.bufferLoader = nil
    else:
      i += ex.len
      if r.buffer.smartResizeAdd(ex, r.freeBefore) and r.freeBefore != 0:
        result = r.freeBefore
        r.freeBefore = 0
