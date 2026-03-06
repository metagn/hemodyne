import ./stringresize, lib/asyncwrapper

type AsyncArtery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): Future[int] {.async.}
    ## returns number of characters consumed
    ## assumed that something is wrong if 0 characters consumed
  freeAfter*: int

proc initAsyncArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): Future[int] {.async.} = nil): AsyncArtery {.inline.} =
  AsyncArtery(buffer: buffer, bufferConsumer: consumer)

proc initAsyncArtery*(consumer: proc (x: openArray[char]): Future[int] {.async.}): AsyncArtery {.inline.} =
  AsyncArtery(buffer: "", bufferConsumer: consumer)

proc setFreeAfter*(r: var AsyncArtery, freeAfter: int) {.inline.} =
  r.freeAfter = freeAfter

proc resetFreeAfter*(r: var AsyncArtery) {.inline.} =
  r.freeAfter = 0

proc addToBuffer*(r: var AsyncArtery, s: sink string): int =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, s, r.freeAfter):
    result = r.freeAfter
    r.freeAfter = 0

proc addToBuffer*(r: var AsyncArtery, c: char): int =
  ## returns removed characters from start of buffer
  result = 0
  if smartResizeAdd(r.buffer, [c], r.freeAfter):
    result = r.freeAfter
    r.freeAfter = 0

proc flushBufferOnce*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of flushed characters
  if not r.bufferConsumer.isNil:
    result = await r.bufferConsumer(r.buffer.toOpenArray(since, r.buffer.len - 1))
    if result == 0:
      r.bufferConsumer = nil
  else:
    result = r.buffer.len - since

proc flushBuffer*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of flushed characters
  var pos = since
  while pos < r.buffer.len:
    let ex = await flushBufferOnce(r, since)
    if ex == 0:
      break
    else:
      pos += ex
  result = pos - since

proc flushBufferFull*(r: var AsyncArtery, since: int): Future[int] {.async.} =
  ## returns number of flushed characters
  result = await flushBuffer(r, since)
  if not r.bufferConsumer.isNil:
    let ex = await r.bufferConsumer([])
    discard ex # unused
    r.bufferConsumer = nil
