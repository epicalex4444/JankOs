/**
 * @file attributes.h
 * @brief shortens attribute syntax with macros
 */

#pragma once

#define NORETURN __attribute__((noreturn)) ///< tell gcc that a function won't ever return
#define PACKED __attribute__((packed))  ///< forces structs to have no empty space
#define NAKED __attribute__((naked)) ///< makes it so gcc doesn't setup stack frame
#define ALWAYS_INLINE __attribute__((always_inline)) ///< forces function to be inlined
