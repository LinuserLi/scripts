#!/usr/bin/env python
#encoding: utf-8

for i in range(1,10):
     for j in range(1,i+1):
         print "\033[47;30m" + str(i) + '*' + str(j) + '=' + str(i*j) + "\033[0m",
     print ''


