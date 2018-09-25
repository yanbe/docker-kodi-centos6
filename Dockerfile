FROM centos:6.10

# install basic X Window System
RUN 	yum install -y \
		dbus \
		dbus-x11 \
		udev \
		xorg-x11-server-Xorg \
		xorg-x11-xinit \
		xterm \
	&& echo 'exec xterm' > /root/.xinitrc
	
RUN	yum install -y centos-release-scl \
	&& yum install -y \
		scl-utils \
		devtoolset-3-gcc \
		devtoolset-3-gcc-c++ \
		# for configure tools/depends in XBMC
		zip \
		unzip \
		m4 \
		# autoconf
		perl \
		# gettext
		patch \
		# cmake
		libcurl-devel \
		# TexturePacker
		glibc-static \
		# cmake \
		zlib \
		zlib-devel \
	&& source /opt/rh/devtoolset-6/enable

RUN	curl -L https://github.com/xbmc/xbmc/archive/{17.6-Krypton.tar.gz} --output "/$HOME/#1" \
	&& cd $HOME \
	&& tar zxvf 17.6-Krypton.tar.gz \
	&& cd $HOME/xbmc-17.6-Krypton \
	# && sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' tools/depends/native/TexturePacker/src/TexturePacker.cpp \
	# && sed -i -E 's/(#include "ActiveAEFilter.h")/#define __STDC_FORMAT_MACROS\n#include <inttypes.h>\n\1/' xbmc/cores/AudioEngine/Engines/ActiveAE/ActiveAEFilter.cpp \
	# && sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' xbmc/music/MusicDatabase.cpp \
	&& sed -i -E 's/(\$\(MAKE\) -C \$\(PLATFORM\))/\1 CFLAGS=-lrt/' tools/depends/target/libnfs/Makefile \
	&& cd $HOME/xbmc-17.6-Krypton/tools/depends \
	&& ./bootstrap \
	&& ./configure --prefix=/opt/xbmc-deps \
	&& make -j$(getconf _NPROCESSORS_ONLN)

RUN	cd $HOME/xbmc-17.6-Krypton \
	&& bootstrap \
	&& ./configure \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \

COPY services.sh /usr/local/bin/

CMD [ "/usr/local/bin/services.sh" ]
