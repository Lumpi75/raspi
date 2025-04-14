
#include "sg_lgpio.h"
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>

int res;
int Gpio_handle;

int Gpiod_export(void)
{
    FILE *fp;
    char buff[4];
    fp = popen("cat /proc/cpuinfo | grep 'Pi 5'", "r");
    if (fp == NULL) 
    {
        printf("The Raspberry PI model is not determine!\n");
        return -1;
    }

    if(fgets(buff, sizeof(buff), fp) != NULL)//Pi 5
    {
        Gpio_handle = lgGpiochipOpen(4);
        if (Gpio_handle < 0 )
        {
            printf( "gpiochip4 open failed\n");
            return -1;
        }
	    printf("open pi 5 gpiochip\n");
    }
    else //other model of Pi
    {
        Gpio_handle = lgGpiochipOpen(0);
        if (Gpio_handle < 0 )
        {
            printf( "gpiochip0 open failed\n");
            return -1;
        }
	    printf("open pi gpiochip\n");
    }
        
    return 0;
}

int Gpiod_set_pinmode(int pin_number,int mode)
{
    if(mode == LGPIO_OUTPUT)
    {
        lgGpioClaimOutput(Gpio_handle, 0, pin_number, LGPIO_LOW);
    }
    if(mode == LGPIO_INPUT)
    {
        lgGpioClaimInput(Gpio_handle, 0,pin_number);		
    }
    return 0;
    
}

int Gpiod_read_pin(int pin_number)
{
    uint8_t Read_value = 0;
    res = lgGpioRead(Gpio_handle,pin_number);

    return (res);	
}

int Gpiod_write_pin(int pin_number, int value)
{
    lgGpioWrite(Gpio_handle, pin_number, value);
}

