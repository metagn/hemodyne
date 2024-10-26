const asyncBackend {.strdefine.} = ""

when asyncBackend == "chronos":
  import chronos
else:
  import asyncdispatch

import ./stringresize

type AsyncArtery* = object
  buffer*: string
  bufferConsumer*: proc (x: openArray[char]): Future[int] {.async.}
    ## returns number of characters consumed
  freeAfter*: int

proc initAsyncArtery*(buffer: sink string = "", consumer: proc (x: openArray[char]): Future[int] {.async.} = nil): AsyncArtery {.inline.} =
  AsyncArtery(buffer: buffer, bufferConsumer: consumer)

proc initAsyncArtery*(consumer: proc (x: openArray[char]): Future[int] {.async.}): AsyncArtery {.inline.} =
  AsyncArtery(buffer: "", bufferConsumer: consumer)

proc setFreeAfter*(r: var AsyncArtery, freeAfter: int) {.inline.} =
  r.freeAfter = freeAfter

proc resetFreeAfter*(r: var AsyncArtery) {.inline.} =
  r.freeAfter = 0

proc writeBuffer*(r: var AsyncArtery, s: sink string): int =
  ## returns shift to buffer position, can be negative
  result = s.len
  if smartResizeAdd(r.buffer, s, r.freeAfter):
    result -= r.freeAfter

proc flushBufferOne*(r: var AsyncArtery) {.async.} =
  if not r.bufferConsumer.isNil:
    let ex = await r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
    else:
      r.freeAfter += ex

proc flushBufferBy*(r: var AsyncArtery, n: int) {.async.} =
  var i = 0
  while not r.bufferConsumer.isNil and i < n:
    let ex = await r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
    else:
      i += ex
      r.freeAfter += ex

proc flushBufferRuneStart*(r: var AsyncArtery, c: char) {.async.} =
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
    await flushBufferBy(r, n)

proc flushBufferAll*(r: var AsyncArtery) {.async.} =
  while not r.bufferConsumer.isNil:
    let ex = await r.bufferConsumer(r.buffer.toOpenArray(r.freeAfter, r.buffer.len - 1))
    if ex == 0:
      r.bufferConsumer = nil
      return
    else:
      r.freeAfter += ex
