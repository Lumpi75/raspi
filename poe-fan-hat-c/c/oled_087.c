#include <stdio.h>
#include <string.h>
#include "oled_font.h"
#include <unistd.h>
#include <stdint.h>
#include "oled_087.h"

int I2C_handle;
uint8_t gram[144][4];

void LG_I2C_Init(uint8_t dev_addr)
{
    I2C_handle = lgI2cOpen(1, dev_addr, 0);//use i2c_1
}

void I2C_write_cmd(uint8_t value)
{
   lgI2cWriteI2CBlockData(I2C_handle,0x00,(char *)&value,1);
}

void I2C_write_data(uint8_t value)
{
   lgI2cWriteI2CBlockData(I2C_handle,0x40,(char *)&value,1);
}

void Oled_Init(void)
{
    LG_I2C_Init(DEV_ADDR);
    I2C_write_cmd(0xAE);//display off
    I2C_write_cmd(0x00);//set lower column address
    I2C_write_cmd(0x10);//set higher column address
    I2C_write_cmd(0x40);//set display start line
    I2C_write_cmd(0xB0);//set page address
    I2C_write_cmd(0x81);//contract control
    I2C_write_cmd(0xC5);//128
    I2C_write_cmd(0xA1);//set segment remap 0xa0
    I2C_write_cmd(0xA6);//normal / reverse
    I2C_write_cmd(0xA8);//multiplex ratio
    I2C_write_cmd(0x1F);//duty =1/32
    I2C_write_cmd(0xC0);//com scan direction 0xc0
    I2C_write_cmd(0xD3);//set display offset
    I2C_write_cmd(0x00);//0x20
    I2C_write_cmd(0xD5);//set osc division
    I2C_write_cmd(0x80);
    I2C_write_cmd(0xD9);//set pre-charge period
    I2C_write_cmd(0x22);//0x22
    I2C_write_cmd(0xDA);//set com pins
    I2C_write_cmd(0x12);
    I2C_write_cmd(0xDB);//set vcomh
    I2C_write_cmd(0x20);
    I2C_write_cmd(0x8D);//set_charge_pump 0x14:9v 0x15:7.5v
    I2C_write_cmd(0x14);//15
    Oled_clear();
    I2C_write_cmd(0xAF) ;//display on
    I2C_write_cmd(0xA6);   
}



void Oled_clear(void)
{
    uint16_t i,n;
    for(i=0;i<4;i++)
    {
        for(n=0;n<128;n++)
        {
            gram[n][i] = 0;
        }
    }
    Oled_refresh();
}

void Oled_refresh(void)
{
    uint16_t i,j;
    for(i=0;i<4;i++)
    {
        I2C_write_cmd(0xB0+i);
        I2C_write_cmd(0x0);
        I2C_write_cmd(0x10);   
        for(j=0;j<128;j++)
            I2C_write_data(gram[j][i]);
    }    
}

void display_on(void)
{
    I2C_write_cmd(0x8D);//enable the charge_pump
    I2C_write_cmd(0x14);//turn on the charge_pump
    I2C_write_cmd(0xAF);//light up screen
}

void display_off(void)
{
    I2C_write_cmd(0x8D);//enable the charge_pump
    I2C_write_cmd(0x10);//turn off the charge_pump
    I2C_write_cmd(0xAE);//close screen
}
        
void draw_point(uint8_t x,uint8_t y,uint8_t t)
{
    uint8_t i,n,m;
    i = y/8;
    m = y%8;
    n = 1<<m;
    if(t)
    {
        gram[x][i]|=n;
    }
    else
    {
        gram[x][i] = ~gram[x][i];
        gram[x][i]|=n;
        gram[x][i]=~gram[x][i];
    }
}
    
void draw_char(uint8_t x,uint8_t y,char ch,uint8_t size1,uint8_t mode)
{
    uint8_t i,m,temp,size2,chr1;
    uint8_t x0 = x;
    uint8_t y0 = y;
    if(size1==8)
        size2 = 6;
    else
    {
        //if(size1%8) tmp=1;
        //else tmp = 0;
        size2 = (size1/8 + ((size1%8)?1:0))*(size1/2);
    }
    chr1 = ch-' ';
    for(i=0;i<size2;i++)
    {
        if(size1==8)
        {
            temp = asc2_0806[chr1][i];
        }
        else if(size1==12)
        {
            temp = asc2_1206[chr1][i];
        }
        else if(size1==16)
        {
            temp = asc2_1608[chr1][i];
        }
        else if(size1==24)
        {
            temp = asc2_2412[chr1][i];
        }
        else 
        {
            return;
        }
        for(m=0;m<8;m++)
        {
            if (temp&0x01)
            {
                draw_point(x,y,mode);
            }
            else
            {
                draw_point(x,y,!mode);
            }
            temp >>=1;
            y++;
        }
        x++;
        if((size1!=8) && (x-x0)==size1/2)
        {
            x=x0;
            y0=y0+8;
        }
        y=y0;
    }
}
void draw_string(uint8_t x,uint8_t y,char *strs,uint8_t size1,uint8_t mode)
{
    while((*strs>=' ')&&(*strs<'~'))
    {
        draw_char(x,y,*strs,size1,mode);
        if (size1==8)
        {
            x =x+6;
        }
        else
        {
            x = x+size1/2;
        }
        strs++;
    }
}


























