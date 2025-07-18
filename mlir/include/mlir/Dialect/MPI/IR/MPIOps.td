//===- MPIops.td - Message Passing Interface Ops -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MPI_MLIR_IR_MPIOPS_TD
#define MPI_MLIR_IR_MPIOPS_TD

include "mlir/Dialect/MPI/IR/MPI.td"
include "mlir/Dialect/MPI/IR/MPITypes.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class MPI_Op<string mnemonic, list<Trait> traits = []>
    : Op<MPI_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// InitOp
//===----------------------------------------------------------------------===//

def MPI_InitOp : MPI_Op<"init", []> {
  let summary =
      "Initialize the MPI library, equivalent to `MPI_Init(NULL, NULL)`";
  let description = [{
    This operation must preceed most MPI calls (except for very few exceptions,
    please consult with the MPI specification on these).

    Passing &argc, &argv is not supported currently.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "attr-dict (`:` type($retval)^)?";
}

//===----------------------------------------------------------------------===//
// CommWorldOp
//===----------------------------------------------------------------------===//

def MPI_CommWorldOp : MPI_Op<"comm_world", [Pure]> {
  let summary = "Get the World communicator, equivalent to `MPI_COMM_WORLD`";
  let description = [{
    This operation returns the predefined MPI_COMM_WORLD communicator.
  }];

  let results = (outs MPI_Comm : $comm);

  let assemblyFormat = "attr-dict `:` type(results)";
}

//===----------------------------------------------------------------------===//
// CommRankOp
//===----------------------------------------------------------------------===//

def MPI_CommRankOp : MPI_Op<"comm_rank", [Pure]> {
  let summary = "Get the current rank, equivalent to "
                "`MPI_Comm_rank(comm, &rank)`";
  let description = [{
    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (ins MPI_Comm : $comm);

  let results = (
    outs Optional<MPI_Retval> : $retval,
    I32 : $rank
  );

  let assemblyFormat = "`(` $comm `)` attr-dict `:` type(results)";
  let hasCanonicalizer = 1;
}

//===----------------------------------------------------------------------===//
// CommSizeOp
//===----------------------------------------------------------------------===//

def MPI_CommSizeOp : MPI_Op<"comm_size", [Pure]> {
  let summary = "Get the size of the group associated to the communicator, "
                "equivalent to `MPI_Comm_size(comm, &size)`";
  let description = [{
    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (ins MPI_Comm : $comm);

  let results = (
    outs Optional<MPI_Retval> : $retval,
    I32 : $size
  );

  let assemblyFormat = "`(` $comm `)` attr-dict `:` type(results)";
}

//===----------------------------------------------------------------------===//
// CommSplitOp
//===----------------------------------------------------------------------===//

def MPI_CommSplitOp : MPI_Op<"comm_split", [Pure]> {
  let summary = "Partition the group associated with the given communicator into "
                "disjoint subgroups";
  let description = [{
    This operation splits the communicator into multiple sub-communicators.
    The color value determines the group of processes that will be part of the
    new communicator. The key value determines the rank of the calling process
    in the new communicator.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (ins MPI_Comm : $comm, I32 : $color, I32 : $key);

  let results = (
    outs Optional<MPI_Retval> : $retval,
    MPI_Comm : $newcomm
  );

  let assemblyFormat = "`(` $comm `,` $color `,` $key `)` attr-dict `:` "
                       "type(results)";
}

//===----------------------------------------------------------------------===//
// SendOp
//===----------------------------------------------------------------------===//

def MPI_SendOp : MPI_Op<"send", []> {
  let summary =
      "Equivalent to `MPI_Send(ptr, size, dtype, dest, tag, comm)`";
  let description = [{
    MPI_Send performs a blocking send of `size` elements of type `dtype` to rank
    `dest`. The `tag` value and communicator enables the library to determine 
    the matching of multiple sends and receives between the same ranks.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (
    ins AnyMemRef : $ref,
    I32 : $tag,
    I32 : $dest,
    MPI_Comm : $comm
  );

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "`(` $ref `,` $tag `,` $dest `,` $comm `)` attr-dict `:` "
                       "type($ref) `,` type($tag) `,` type($dest)"
                       "(`->` type($retval)^)?";
  let hasCanonicalizer = 1;
}

//===----------------------------------------------------------------------===//
// ISendOp
//===----------------------------------------------------------------------===//

def MPI_ISendOp : MPI_Op<"isend", []> {
  let summary =
      "Equivalent to `MPI_Isend(ptr, size, dtype, dest, tag, comm)`";
  let description = [{
    MPI_Isend begins a non-blocking send of `size` elements of type `dtype` to
    rank `dest`. The `tag` value and communicator enables the library to
    determine the matching of multiple sends and receives between the same
    ranks.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (
    ins AnyMemRef : $ref,
    I32 : $tag,
    I32 : $dest,
    MPI_Comm : $comm
  );

  let results = (
    outs Optional<MPI_Retval>:$retval,
    MPI_Request : $req
  );

  let assemblyFormat = "`(` $ref `,` $tag `,` $dest `,` $comm`)` attr-dict "
                       "`:` type($ref) `,` type($tag) `,` type($dest) "
                       "`->` type(results)";
  let hasCanonicalizer = 1;
}

//===----------------------------------------------------------------------===//
// RecvOp
//===----------------------------------------------------------------------===//

def MPI_RecvOp : MPI_Op<"recv", []> {
  let summary = "Equivalent to `MPI_Recv(ptr, size, dtype, source, tag, "
                "comm, MPI_STATUS_IGNORE)`";
  let description = [{
    MPI_Recv performs a blocking receive of `size` elements of type `dtype` 
    from rank `source`. The `tag` value and communicator enables the library to
    determine the matching of multiple sends and receives between the same 
    ranks.

    The MPI_Status is set to `MPI_STATUS_IGNORE`, as the status object 
    is not yet ported to MLIR.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (
    ins AnyMemRef : $ref,
    I32 : $tag, I32 : $source,
    MPI_Comm : $comm
  );

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "`(` $ref `,` $tag `,` $source `,` $comm `)` attr-dict"
                       " `:` type($ref) `,` type($tag) `,` type($source) "
                       "(`->` type($retval)^)?";
  let hasCanonicalizer = 1;
}

//===----------------------------------------------------------------------===//
// IRecvOp
//===----------------------------------------------------------------------===//

def MPI_IRecvOp : MPI_Op<"irecv", []> {
  let summary = "Equivalent to `MPI_Irecv(ptr, size, dtype, source, tag, "
                "comm, &req)`";
  let description = [{
    MPI_Irecv begins a non-blocking receive of `size` elements of type `dtype` 
    from rank `source`. The `tag` value and communicator enables the library to
    determine the matching of multiple sends and receives between the same 
    ranks.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (
    ins AnyMemRef : $ref,
    I32 : $tag,
    I32 : $source,
    MPI_Comm : $comm
  );

  let results = (
    outs Optional<MPI_Retval>:$retval,
    MPI_Request : $req
  );

  let assemblyFormat = "`(` $ref `,` $tag `,` $source `,` $comm`)` attr-dict "
                       "`:` type($ref) `,` type($tag) `,` type($source)"
                       "`->` type(results)";
  let hasCanonicalizer = 1;
}

//===----------------------------------------------------------------------===//
// AllReduceOp
//===----------------------------------------------------------------------===//

def MPI_AllReduceOp : MPI_Op<"allreduce", []> {
  let summary = "Equivalent to `MPI_Allreduce(sendbuf, recvbuf, op, comm)`";
  let description = [{
    MPI_Allreduce performs a reduction operation on the values in the sendbuf
    array and stores the result in the recvbuf array. The operation is 
    performed across all processes in the communicator.

    The `op` attribute specifies the reduction operation to be performed.
    Currently only the `MPI_Op` predefined in the standard (e.g. `MPI_SUM`) are
    supported.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (
    ins AnyMemRef : $sendbuf,
    AnyMemRef : $recvbuf,
    MPI_ReductionOpEnum : $op,
    MPI_Comm : $comm
  );

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "`(` $sendbuf `,` $recvbuf `,` $op `,` $comm `)` "
                       "attr-dict `:` type($sendbuf) `,` type($recvbuf) "
                       "(`->` type($retval)^)?";
}

//===----------------------------------------------------------------------===//
// BarrierOp
//===----------------------------------------------------------------------===//

def MPI_Barrier : MPI_Op<"barrier", []> {
  let summary = "Equivalent to `MPI_Barrier(comm)`";
  let description = [{
    MPI_Barrier blocks execution until all processes in the communicator have
    reached this routine.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (ins MPI_Comm : $comm);

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = [{
    `(` $comm `)` attr-dict
    (`->` type($retval)^)?
  }];
}

//===----------------------------------------------------------------------===//
// WaitOp
//===----------------------------------------------------------------------===//

def MPI_Wait : MPI_Op<"wait", []> {
  let summary = "Equivalent to `MPI_Wait(req, MPI_STATUS_IGNORE)`";
  let description = [{
    MPI_Wait blocks execution until the request has completed.

    The MPI_Status is set to `MPI_STATUS_IGNORE`, as the status object 
    is not yet ported to MLIR.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let arguments = (ins MPI_Request : $req);

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "`(` $req `)` attr-dict `:` type($req) (`->` type($retval) ^)?";
}

//===----------------------------------------------------------------------===//
// FinalizeOp
//===----------------------------------------------------------------------===//

def MPI_FinalizeOp : MPI_Op<"finalize", []> {
  let summary = "Finalize the MPI library, equivalent to `MPI_Finalize()`";
  let description = [{
    This function cleans up the MPI state. Afterwards, no MPI methods may 
    be invoked (excpet for MPI_Get_version, MPI_Initialized, and MPI_Finalized).
    Notably, MPI_Init cannot be called again in the same program.

    This operation can optionally return an `!mpi.retval` value that can be used
    to check for errors.
  }];

  let results = (outs Optional<MPI_Retval>:$retval);

  let assemblyFormat = "attr-dict (`:` type($retval)^)?";
}

//===----------------------------------------------------------------------===//
// RetvalCheckOp
//===----------------------------------------------------------------------===//

def MPI_RetvalCheckOp : MPI_Op<"retval_check", []> {
  let summary = "Check an MPI return value against an error class";
  let description = [{
    This operation compares MPI status codes to known error class
    constants such as `MPI_SUCCESS`, or `MPI_ERR_COMM`.
  }];

  let arguments = (
    ins MPI_Retval:$val,
    MPI_ErrorClassAttr:$errclass
  );

  let results = (
    outs I1:$res
  );

  let assemblyFormat = "$val `=` $errclass attr-dict `:` type($res)";
}

//===----------------------------------------------------------------------===//
// ErrorClassOp
//===----------------------------------------------------------------------===//

def MPI_ErrorClassOp : MPI_Op<"error_class", []> {
  let summary = "Get the error class from an error code, equivalent to "
                "the `MPI_Error_class` function";
  let description = [{
    `MPI_Error_class` maps return values from MPI calls to a set of well-known
    MPI error classes.
  }];

  let arguments = (
    ins MPI_Retval:$val
  );

  let results = (
    outs MPI_Retval:$errclass
  );

  let assemblyFormat = "$val attr-dict `:` type($val)";
}

#endif // MPI_MLIR_IR_MPIOPS_TD
