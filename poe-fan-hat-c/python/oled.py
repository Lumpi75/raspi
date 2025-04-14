import time
import smbus
import numpy as np
from char_data import *

OLED_W = 128
OLED_H = 32

class OLED_087:
    def __init__(self):
        self.i2c = smbus.SMBus(1)
        self.dev_addr = 0x3c
        self.gram = np.zeros((144,4),dtype=np.int8)
        #self.gram = self.gram.dtype(int)
        
    def write_byte(self,reg,value):
        self.i2c.write_byte_data(self.dev_addr,reg,value)
        
    def write_command(self,cmd):
        self.write_byte(0x00,cmd)
        
    def write_data(self,data):
        self.write_byte(0x40,data)
        
    def init(self):
        self.write_command(0xAE)#display off
        self.write_command(0x00)#set lower column address
        self.write_command(0x10)#set higher column address
        self.write_command(0x40)#set display start line
        self.write_command(0xB0)#set page address
        self.write_command(0x81)#contract control
        self.write_command(0xC5)#128
        self.write_command(0xA1)#set segment remap 0xa0
        self.write_command(0xA6)#normal / reverse
        self.write_command(0xA8)#multiplex ratio
        self.write_command(0x1F)#duty =1/32
        self.write_command(0xC0)#com scan direction 0xc0
        self.write_command(0xD3)#set display offset
        self.write_command(0x00)#0x20
        self.write_command(0xD5)#set osc division
        self.write_command(0x80)
        self.write_command(0xD9)#set pre-charge period
        self.write_command(0x22)#0x22
        self.write_command(0xDA)#set com pins
        self.write_command(0x12)
        self.write_command(0xDB)#set vcomh
        self.write_command(0x20)
        self.write_command(0x8D)#set_charge_pump 0x14:9v 0x15:7.5v
        self.write_command(0x14)#15
        self.clear()
        self.write_command(0xAF) #display on
        self.write_command(0xA6)
        
    def clear(self):
        for i in range(4):
            for n in range(128):
                self.gram[n][i] = 0
        self.refresh()
        
    def refresh(self):
        for i in range(4):
            self.write_command(0xB0+i)
            self.write_command(0x00)
            self.write_command(0x10)
            for j in range(128):
                self.write_data(self.gram[j][i])
    def display_on(self):
        self.write_command(0x8D)#enable the charge_pump
        self.write_command(0x14)#turn on the charge_pump
        self.write_command(0xAF)#light up screen

    def display_off(self):
        self.write_command(0x8D)#enable the charge_pump
        self.write_command(0x10)#turn off the charge_pump
        self.write_command(0xAE)#close screen
        
    def draw_point(self,x,y,t):
        i = y//8
        m = y%8
        n = 1<<m
        if t:
            self.gram[x][i]|=n
        else:
            self.gram[x][i] = ~self.gram[x][i]
            self.gram[x][i]|=n
            self.gram[x][i]=~self.gram[x][i]
    
    def draw_char(self,x,y,ch,size1,mode):
        x0 = x
        y0 = y
        if size1==8:
            size2 = 6
        else:
            tmp = 1 if size1%8 else 0
            size2 = (size1//8 + tmp)*(size1//2)
        chr1 = ord(ch)-ord(' ')
        for i in range(size2):
            if size1==8:
                temp = asc2_0806[chr1][i]
            elif size1==12:
                temp = asc2_1206[chr1][i]
            elif size1==16:
                temp = asc2_1608[chr1][i]
            elif size1==24:
                temp = asc2_2412[chr1][i]
            else :
                return 0
            for m in range(8):
                if temp&0x01:
                    self.draw_point(x,y,mode)
                else:
                    self.draw_point(x,y,not mode)
                temp >>=1
                y = y+1
            x = x+1
            if size1!=8 and (x-x0)==size1//2:
                x=x0
                y0=y0+8
            y=y0
    def draw_string(self,x,y,strs,size1,mode):
        for i in range(len(strs)):
            if ord(strs[i]) >= ord(' ') and ord(strs[i]) <= ord('~'):
                self.draw_char(x,y,strs[i],size1,mode)
                if size1==8:
                    x =x+6
                else:
                    x = x+size1//2
        
        
        
        
        
        
        
        
        
        
        