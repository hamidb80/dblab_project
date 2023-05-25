import std/strutils

template i*(smth: string): int =
  parseInt smth

template toStr*(smth): int =
  $smth

