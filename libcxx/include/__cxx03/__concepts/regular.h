//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef _LIBCPP___CXX03___CONCEPTS_REGULAR_H
#define _LIBCPP___CXX03___CONCEPTS_REGULAR_H

#include <__cxx03/__concepts/equality_comparable.h>
#include <__cxx03/__concepts/semiregular.h>
#include <__cxx03/__config>

#if !defined(_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER)
#  pragma GCC system_header
#endif

_LIBCPP_BEGIN_NAMESPACE_STD

#if _LIBCPP_STD_VER >= 20

// [concept.object]

template <class _Tp>
concept regular = semiregular<_Tp> && equality_comparable<_Tp>;

#endif // _LIBCPP_STD_VER >= 20

_LIBCPP_END_NAMESPACE_STD

#endif // _LIBCPP___CXX03___CONCEPTS_REGULAR_H
