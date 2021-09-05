#define SET_BIT(value, bitNum) ((value) |= (1 << (bitNum)))
#define CLEAR_BIT(value, bitNum) ((value) &= ~(1 << (bitNum)))
#define TOGGLE_BIT(value, bitNum) ((value) ^= (1 << (bitNum)))
#define READ_BIT(value, bitNum) ((value) & (1 << (bitNum)))
