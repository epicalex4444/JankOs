/**
 * @file math.h
 * @brief math functions and macros
 */

#include "types.h"
#include "attributes.h"

INLINE u64 uint_ceil(u64 value, u64 round) {
    return (value / round + (value % round != 0)) * round;
}

INLINE u64 uint_floor(u64 value, u64 round) {
    return value / round * round;
}

INLINE u64 uint_round(u64 value, u64 round) {
    if (value % round >= round / 2) {
        return (value / round + 1) * round;
    }
    return value / round * round;
}

INLINE i64 int_ceil(i64 value, i64 round) {
    if (value < 0) {
        return (value / round - (value % round != 0)) * round;
    }
    return (value / round + (value % round != 0)) * round;
}

INLINE i64 int_floor(i64 value, i64 round) {
    return value / round * round;
}

INLINE i64 int_round(i64 value, i64 round) {
    if (value < 0) {
        if (value % round <= round / -2) {
            return (value / round - 1) * round;
        }
    } else {
        if (value % round >= round / 2) {
            return (value / round + 1) * round;
        }
    }
    return value / round * round;
}
