#ifndef TYPES_H
#define TYPES_H

//using x86_64 cross compiler, so data types should have consistent sizes

//booleans
#define bool _Bool
#define true 1
#define false 0

//unsigned integers
#define u8 unsigned char
#define u16 unsigned short
#define u32 unsigned int
#define u64 unsigned long

//signed integers
#define i8 signed char
#define i16 short
#define i32 int
#define i64 long

//floats
#define f32 float
#define f64 double

#endif
