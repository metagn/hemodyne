import ./stringresize, std/streams

type Artery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): int
    ## returns number of characters consumed
    ## assumed that something is wrong if 0 characters consumed
  freeBefore*: int

proc initArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): int = nil): Artery {.inline.} =
  Artery(buffer: buffer, bufferConsumer: consumer)

proc initArtery*(consumer: proc (x: openArray[char]): int): Artery {.inline.} =
  Artery(buffer: "", bufferConsumer: consumer)

proc initArtery*(stream: Stream): Artery {.inline.} =
  Artery(buffer: newStringOfCap(64), bufferConsumer: proc (x: openArray[char]): int =
    when defined(js) or defined(nimscript):
      var s = newString(x.len)
      for i in 0 ..< x.len:
        s[i] = x[i]
      stream.write(s)
    else:
      stream.write(x)
    result = x.len)

{.push checks: off, stacktrace: off.}

proc setFreeBefore*(r: var Artery, freeBefore: int) {.inline.} =
  r.freeBefore = freeBefore

proc resetFreeBefore*(r: var Artery) {.inline.} =
  r.freeBefore = 0

proc addToBuffer*(r: var Artery, s: openArray[char]): int {.inline.} =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, s, r.freeBefore):
    result = r.freeBefore
    r.freeBefore = 0

proc addToBuffer*(r: var Artery, c: char): int {.inline.} =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, [c], r.freeBefore):
    result = r.freeBefore
    r.freeBefore = 0

proc consumeBufferOnce*(r: var Artery, since: int): int {.inline.} =
  ## returns number of consumed characters
  result = 0
  if not r.bufferConsumer.isNil:
    result = r.bufferConsumer(r.buffer.toOpenArray(since, r.buffer.len - 1))
    if result == 0:
      r.bufferConsumer = nil

proc consumeBuffer*(r: var Artery, since: int): int {.inline.} =
  ## returns number of consumed characters
  result = 0
  if not r.bufferConsumer.isNil:
    var pos = since
    while pos < r.buffer.len:
      let ex = consumeBufferOnce(r, pos)
      if ex == 0:
        break
      else:
        pos += ex
    result = pos - since

proc consumeBufferFull*(r: var Artery, since: int): int {.inline.} =
  ## returns number of consumed characters
  result = 0
  if not r.bufferConsumer.isNil:
    result = consumeBuffer(r, since)
    let ex = r.bufferConsumer([])
    discard ex # unused
    r.bufferConsumer = nil

proc flushBufferOnce*(r: var Artery, since: int): int {.inline.} =
  result = consumeBufferOnce(r, since)
proc flushBuffer*(r: var Artery, since: int): int {.inline.} =
  result = consumeBuffer(r, since)
proc flushBufferFull*(r: var Artery, since: int): int {.inline.} =
  result = consumeBufferFull(r, since)

{.pop.}
