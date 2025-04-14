
#ifndef _OLED_087_H_
#define _OLED_087_H_

#include <stdint.h>
#include <lgpio.h>

#define DEV_ADDR 0x3c

void LG_I2C_Init(uint8_t dev_addr);
void Oled_Init(void); 
void Oled_clear(void);   
void Oled_refresh(void);
void display_on(void);
void display_off(void);
void draw_point(uint8_t x,uint8_t y,uint8_t t);
void draw_char(uint8_t x,uint8_t y,char ch,uint8_t size1,uint8_t mode);
void draw_string(uint8_t x,uint8_t y,char *strs,uint8_t size1,uint8_t mode);

#endif
