#!/bin/bash

/etc/init.d/messagebus start
/etc/init.d/haldaemon start
startx &
sleep 1
tail -n 100 -f /var/log/Xorg.0.log
/etc/init.d/haldaemon stop
/etc/init.d/messagebus stop
