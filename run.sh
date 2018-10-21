#!/bin/bash

service messagebus start
service haldaemon start
service acpid start
startx &
sleep 1
tail -n 100 -f /var/log/Xorg.0.log
service acpid stop
service haldaemon stop
service messagebus stop
