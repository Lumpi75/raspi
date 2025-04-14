
#ifndef _SG_LGPIO_H_
#define _SG_LGPIO_H_

#include <stdint.h>
#include <stdio.h>
#include <lgpio.h>

#define LGPIO_INPUT  0
#define LGPIO_OUTPUT 1

#define LGPIO_LOW  0
#define LGPIO_HIGH 1

int Gpiod_export(void);
int Gpiod_set_pinmode(int pin_number,int mode);
int Gpiod_read_pin(int pin_number);
int Gpiod_write_pin(int Pin, int value);
    

#endif
