#!/usr/bin/env python
import os, sys

for line in sys.stdin:
    line = line.strip()
    bits = line.split('/')
    version = bits[-2]
    jarname = bits[-3]
    group = '.'.join(bits[1:-3])
    if group != jarname:
        print '[' + group + '/' + jarname, '"' + version + '"]'
    else:
        print '[' + jarname, '"' + version + '"]'
