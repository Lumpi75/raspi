import time
import os
import sys
import socket
from char_data import *
from oled import *

def get_ip():
    s = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    s.connect(('8.8.8.8',80))
    ip = s.getsockname()[0]
    s.close()
    return ip
def get_temp():
    with open('/sys/class/thermal/thermal_zone0/temp','rt') as f:
        temp = (int)(f.read())/1000.0
    return temp
if __name__=='__main__':
    oled = OLED_087()
    oled.init()
    oled.clear()
    oled.draw_string(0,2,'IP:                ',12,1)
    oled.draw_string(0,16,'Temp:',16,1)
    while True:
        ip_str = get_ip()
        oled.draw_string(24,2,ip_str,12,1)
        temp = get_temp()
        temp_str = str(((int)(temp*10))/10.0)
        oled.draw_string(40,16,temp_str,16,1)        
        oled.refresh()
        time.sleep(1)