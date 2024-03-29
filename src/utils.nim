import std/[strutils, options]

func toOptionalInt*(s: string, filter: string): Option[int] = 
  if s.isEmptyOrWhitespace or s == filter: none int
  else: some parseInt s

func `or`*(s1, s2: string): string = 
  if s1.isEmptyOrWhitespace: s2
  else: s1

template i*(smth: string): int =
  parseInt smth

template toStr*(smth): int =
  $smth

template raisee*(err, msg): untyped =
  raise newException(err, msg)

template iff*(cond, vtrue, vfalse): untyped =
  if cond: vtrue
  else: vfalse

converter toBigger*(i: int): int64 = i.int64
converter toBigger*(io: Option[int]): Option[int64] = 
  if isSome io: some io.get.int64
  else: none int64