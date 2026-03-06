import ./stringresize, lib/asyncwrapper

type AsyncArtery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): Future[int] {.async.}
    ## returns number of characters consumed
    ## assumed that something is wrong if 0 characters consumed
  freeBefore*: int

proc initAsyncArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): Future[int] {.async.} = nil): AsyncArtery {.inline.} =
  AsyncArtery(buffer: buffer, bufferConsumer: consumer)

proc initAsyncArtery*(consumer: proc (x: openArray[char]): Future[int] {.async.}): AsyncArtery {.inline.} =
  AsyncArtery(buffer: "", bufferConsumer: consumer)

proc setFreeBefore*(r: var AsyncArtery, freeBefore: int) {.inline.} =
  r.freeBefore = freeBefore

proc resetFreeBefore*(r: var AsyncArtery) {.inline.} =
  r.freeBefore = 0

proc addToBuffer*(r: var AsyncArtery, s: sink string): int {.inline.} =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, s, r.freeBefore):
    result = r.freeBefore
    r.freeBefore = 0

proc addToBuffer*(r: var AsyncArtery, c: char): int {.inline.} =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, [c], r.freeBefore):
    result = r.freeBefore
    r.freeBefore = 0

proc consumeBufferOnce*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of consumeed characters
  if not r.bufferConsumer.isNil:
    result = await r.bufferConsumer(r.buffer.toOpenArray(since, r.buffer.len - 1))
    if result == 0:
      r.bufferConsumer = nil
  else:
    result = 0

proc consumeBuffer*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of consumeed characters
  var pos = since
  while pos < r.buffer.len:
    let ex = await consumeBufferOnce(r, since)
    if ex == 0:
      break
    else:
      pos += ex
  result = pos - since

proc consumeBufferFull*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of consumeed characters
  result = await consumeBuffer(r, since)
  if not r.bufferConsumer.isNil:
    let ex = await r.bufferConsumer([])
    discard ex # unused
    r.bufferConsumer = nil

proc flushBufferOnce*(r: var AsyncArtery, since: int): Future[int] {.inline.} =
  result = consumeBufferOnce(r, since)
proc flushBuffer*(r: var AsyncArtery, since: int): Future[int] {.inline.} =
  result = consumeBuffer(r, since)
proc flushBufferFull*(r: var AsyncArtery, since: int): Future[int] {.inline.} =
  result = consumeBufferFull(r, since)
