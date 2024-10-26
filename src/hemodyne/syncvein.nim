import ./stringresize

type Vein* = object
  buffer*: string
    ## buffer string, users need to access directly & keep track of position
  bufferLoader*: proc (): string
    ## loads a string at a time to add to the buffer when needed
    ## set to nil after returning empty string
  freeBefore*: int
    ## position before which we can cull the buffer

proc initVein*(buffer: sink string = "", loader: proc (): string = nil): Vein {.inline.} =
  Vein(buffer: buffer, bufferLoader: loader)

proc initVein*(loader: proc (): string): Vein {.inline.} =
  Vein(buffer: "", bufferLoader: loader)

proc setFreeBefore*(r: var Vein, freeBefore: int) {.inline.} =
  r.freeBefore = freeBefore

proc resetFreeBefore*(r: var Vein) {.inline.} =
  r.freeBefore = 0

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

proc extendBufferRuneStart*(r: var Vein, c: char): int =
  result = 0
  let b = byte(c)
  if (b and 0b10000000) != 0:
    var n = 0
    if b shr 5 == 0b110:
      n = 1
    elif b shr 4 == 0b1110:
      n = 2
    elif b shr 3 == 0b11110:
      n = 3
    elif b shr 2 == 0b111110:
      n = 4
    elif b shr 1 == 0b1111110:
      n = 5
    else:
      return
    result = extendBufferBy(r, n)
