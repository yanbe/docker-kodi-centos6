#!/bin/bash

/etc/init.d/messagebus start
/etc/init.d/haldaemon start
startx
/etc/init.d/haldaemon stop
/etc/init.d/messagebus stop
