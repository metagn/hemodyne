import ./stringresize

type Artery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): int
    ## returns number of characters consumed
  freeAfter*: int

proc initArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): int = nil): Artery {.inline.} =
  Artery(buffer: buffer, bufferConsumer: consumer)

proc initArtery*(consumer: proc (x: openArray[char]): int): Artery {.inline.} =
  Artery(buffer: "", bufferConsumer: consumer)

proc setFreeAfter*(r: var Artery, freeAfter: int) {.inline.} =
  r.freeAfter = freeAfter

proc resetFreeAfter*(r: var Artery) {.inline.} =
  r.freeAfter = 0

proc writeBuffer*(r: var Artery, s: sink string): int =
  ## returns shift to buffer position, can be negative
  result = s.len
  if smartResizeAdd(r.buffer, s, r.freeAfter):
    result -= r.freeAfter

proc flushBufferOne*(r: var Artery) =
  if not r.bufferConsumer.isNil:
    let ex = r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
    else:
      r.freeAfter += ex

proc flushBufferBy*(r: var Artery, n: int) =
  var i = 0
  while not r.bufferConsumer.isNil and i < n:
    let ex = r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
    else:
      i += ex
      r.freeAfter += ex

proc flushBufferRuneStart*(r: var Artery, c: char) =
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
    flushBufferBy(r, n)

proc flushBufferAll*(r: var Artery) =
  while not r.bufferConsumer.isNil:
    let ex = r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
      return
    else:
      r.freeAfter += ex
