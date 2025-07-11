; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py UTC_ARGS: --version 5
; RUN: opt -disable-output -passes='print<access-info>' %s 2>&1 | FileCheck %s

target datalayout = "e-m:e-p:128:128:128"

; Tests with 128 bit inductions and 128 bit pointer width and index size.


define void @backward_i128(ptr %A, i128 %n) {
; CHECK-LABEL: 'backward_i128'
; CHECK-NEXT:    loop:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l = load i32, ptr %gep.A, align 4 ->
; CHECK-NEXT:            store i32 %l, ptr %gep.A.1, align 4
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop

loop:
  %iv = phi i128 [ 0, %entry ], [ %iv.next, %loop ]
  %gep.A = getelementptr inbounds i32, ptr %A, i128 %iv
  %l = load i32, ptr %gep.A
  %iv.1 = add nuw nsw i128 %iv, 1
  %gep.A.1 = getelementptr inbounds i32, ptr %A, i128 %iv.1
  store i32 %l, ptr %gep.A.1
  %iv.next = add i128 %iv, 1
  %ec = icmp eq i128 %iv.next, %n
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}

define void @forward_i128(ptr %A, i128 %n) {
; CHECK-LABEL: 'forward_i128'
; CHECK-NEXT:    loop:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l = load i32, ptr %gep.A.1, align 4 ->
; CHECK-NEXT:            store i32 %l, ptr %gep.A, align 4
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop

loop:
  %iv = phi i128 [ 0, %entry ], [ %iv.next, %loop ]
  %iv.1 = add nuw nsw i128 %iv, 1
  %gep.A.1 = getelementptr inbounds i32, ptr %A, i128 %iv.1
  %l = load i32, ptr %gep.A.1
  %gep.A = getelementptr inbounds i32, ptr %A, i128 %iv
  store i32 %l, ptr %gep.A
  %iv.next = add i128 %iv, 1
  %ec = icmp eq i128 %iv.next, %n
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}

define void @forward_negative_step(ptr %A, i128 %n) {
; CHECK-LABEL: 'forward_negative_step'
; CHECK-NEXT:    loop:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l = load i32, ptr %gep.A, align 4 ->
; CHECK-NEXT:            store i32 %l, ptr %gep.A.1, align 4
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop

loop:
  %iv = phi i128 [ 36893488147419103232, %entry ], [ %iv.next, %loop ]
  %gep.A = getelementptr inbounds i32, ptr %A, i128 %iv
  %l = load i32, ptr %gep.A
  %iv.1 = add nuw nsw i128 %iv, 1
  %gep.A.1 = getelementptr inbounds i32, ptr %A, i128 %iv.1
  store i32 %l, ptr %gep.A.1
  %iv.next = add nsw i128 %iv, -1
  %ec = icmp eq i128 %iv.next, %n
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}

; The induction step is i128 2^63 + 1, which does not fit into a 64 bit signed
; integer.
define void @forward_i128_step_63bit_plus_one(ptr %A, i128 %n) {
; CHECK-LABEL: 'forward_i128_step_63bit_plus_one'
; CHECK-NEXT:    loop:
; CHECK-NEXT:      Report: unsafe dependent memory operations in loop. Use #pragma clang loop distribute(enable) to allow loop distribution to attempt to isolate the offending operations into a separate loop
; CHECK-NEXT:  Unsafe indirect dependence.
; CHECK-NEXT:      Dependences:
; CHECK-NEXT:        IndirectUnsafe:
; CHECK-NEXT:            %l = load i32, ptr %gep.A.1, align 4 ->
; CHECK-NEXT:            store i32 %l, ptr %gep.A, align 4
; CHECK-EMPTY:
; CHECK-NEXT:      Run-time memory checks:
; CHECK-NEXT:      Grouped accesses:
; CHECK-EMPTY:
; CHECK-NEXT:      Non vectorizable stores to invariant address were not found in loop.
; CHECK-NEXT:      SCEV assumptions:
; CHECK-EMPTY:
; CHECK-NEXT:      Expressions re-written:
;
entry:
  br label %loop

loop:
  %iv = phi i128 [ 0, %entry ], [ %iv.next, %loop ]
  %iv.1 = add nuw nsw i128 %iv, 1
  %gep.A.1 = getelementptr inbounds i32, ptr %A, i128 %iv.1
  %l = load i32, ptr %gep.A.1
  %gep.A = getelementptr inbounds i32, ptr %A, i128 %iv
  store i32 %l, ptr %gep.A
  %iv.next = add i128 %iv, 9223372036854775809
  %ec = icmp eq i128 %iv.next, %n
  br i1 %ec, label %exit, label %loop

exit:
  ret void
}
