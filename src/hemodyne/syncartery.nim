import ./stringresize

type Artery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): int
    ## returns number of characters consumed
    ## assumed that something is wrong if 0 characters consumed
  freeAfter*: int

proc initArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): int = nil): Artery {.inline.} =
  Artery(buffer: buffer, bufferConsumer: consumer)

proc initArtery*(consumer: proc (x: openArray[char]): int): Artery {.inline.} =
  Artery(buffer: "", bufferConsumer: consumer)

proc setFreeAfter*(r: var Artery, freeAfter: int) {.inline.} =
  r.freeAfter = freeAfter

proc resetFreeAfter*(r: var Artery) {.inline.} =
  r.freeAfter = 0

proc addToBuffer*(r: var Artery, s: sink string): int =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, s, r.freeAfter):
    result = r.freeAfter
    r.freeAfter = 0

proc addToBuffer*(r: var Artery, c: char): int =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, [c], r.freeAfter):
    result = r.freeAfter
    r.freeAfter = 0

proc flushBufferOnce*(r: var Artery, since: int): int =
  ## returns number of flushed characters
  if not r.bufferConsumer.isNil:
    result = r.bufferConsumer(r.buffer.toOpenArray(since, r.buffer.len - 1))
    if result == 0:
      r.bufferConsumer = nil
  else:
    result = 0

proc flushBuffer*(r: var Artery, since: int): int =
  ## returns number of flushed characters
  var pos = since
  while pos < r.buffer.len:
    let ex = flushBufferOnce(r, pos)
    if ex == 0:
      break
    else:
      pos += ex
  result = pos - since

proc flushBufferFull*(r: var Artery, since: int): int =
  ## returns number of flushed characters
  result = flushBuffer(r, since)
  if not r.bufferConsumer.isNil:
    let ex = r.bufferConsumer([])
    discard ex # unused
    r.bufferConsumer = nil
