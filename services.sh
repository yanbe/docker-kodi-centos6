#!/bin/bash

/etc/init.d/messagebus start
/etc/init.d/haldaemon start
source /opt/rh/python27/enable
/usr/bin/startx
