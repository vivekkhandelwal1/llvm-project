; RUN: llc -mtriple=hexagon -debug-only=isel < %s
; REQUIRES: asserts

define void @g(i1 %cond) {
  ret void
}
