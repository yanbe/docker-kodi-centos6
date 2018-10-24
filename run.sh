#!/bin/bash

rm -f /var/run/messagebus.pid
service messagebus start
service haldaemon start
service acpid start
startx &
sleep 1
tail -n +1 -f /var/log/Xorg.0.log /root/.kodi/temp/kodi.log
service acpid stop
service haldaemon stop
service messagebus stop
