//===- FormExpressions.cpp - Form C-style expressions --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a pass that forms EmitC operations modeling C operators
// into C-style expressions using the emitc.expression op.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/Dialect/EmitC/Transforms/Passes.h"
#include "mlir/Dialect/EmitC/Transforms/Transforms.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
namespace emitc {
#define GEN_PASS_DEF_FORMEXPRESSIONSPASS
#include "mlir/Dialect/EmitC/Transforms/Passes.h.inc"
} // namespace emitc
} // namespace mlir

using namespace mlir;
using namespace emitc;

namespace {
struct FormExpressionsPass
    : public emitc::impl::FormExpressionsPassBase<FormExpressionsPass> {
  void runOnOperation() override {
    Operation *rootOp = getOperation();
    MLIRContext *context = rootOp->getContext();

    // Wrap each C operator op with an expression op.
    OpBuilder builder(context);
    auto matchFun = [&](Operation *op) {
      if (isa<emitc::CExpressionInterface>(*op) &&
          !op->getParentOfType<emitc::ExpressionOp>() &&
          op->getNumResults() == 1)
        createExpression(op, builder);
    };
    rootOp->walk(matchFun);

    // Fold expressions where possible.
    RewritePatternSet patterns(context);
    populateExpressionPatterns(patterns);

    if (failed(applyPatternsGreedily(rootOp, std::move(patterns))))
      return signalPassFailure();
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<emitc::EmitCDialect>();
  }
};
} // namespace
