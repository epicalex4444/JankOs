/**
 * @file types.h
 * @brief macros to redefine data type names
 * @details c numbers are long and don't describe what they represent well
 *          numbers are changed to display thier size and type in as small
 *          a space as possible. A cross compiler is being used so data type
 *          sizes should be consistent, unlike regular compilation.
 */

#ifndef TYPES_H
#define TYPES_H

#define bool _Bool ///< boolean
#define true 1 ///< true
#define false 0 ///< false

#define u8 unsigned char ///< 8 bit unsigned integer
#define u16 unsigned short ///< 16 bit unsigned integer
#define u32 unsigned int ///< 32 bit unsigned integer
#define u64 unsigned long ///< 64 bit unsigned integer

#define i8 signed char ///< 8 bit signed integer
#define i16 short ///< 16 bit signed integer
#define i32 int ///< 32 bit signed integer
#define i64 long ///< 64 bit signed integer

#define f32 float ///< 32 bit float
#define f64 double ///< 64 bit float

#endif
