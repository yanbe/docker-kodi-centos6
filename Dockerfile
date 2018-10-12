FROM centos:6.10

# install basic X Window System
RUN 	echo 'prefer=ftp.riken.jp' >> /etc/yum/pluginconf.d/fastestmirror.conf \
        && yum clean plugins \
	&& yum update -y \
	&& yum install -y \
		dbus \
		dbus-x11 \
		udev \
		xorg-x11-server-Xorg \
		xorg-x11-xinit

ENV BUILD_DEPS  devtoolset-6-gcc \
		devtoolset-6-gcc-c++ \
		cmake3 \
		patch \
		yasm \
		libtool \
		automake \
		autoconf
		
# install Kodi dependencies from yum repositories
RUN 	yum install -y \
		epel-release \
		centos-release-scl \
	&& yum install -y \
		$BUILD_DEPS \
		scl-utils \
		lzo-devel \
		libpng-devel \
		giflib-devel \
		libjpeg-turbo-devel \
		python27 \
		expat-devel \
		libuuid-devel \
		openssl-devel \
		pcre-devel \
		mesa-libGL-devel \
		mesa-libGLU-devel \
		mesa-libEGL-devel \
		libXrandr-devel \
		java-1.8.0-openjdk \
		gettext \
		ghostscript \
		libcurl-devel \
		gperf \
	&& ln -s /usr/bin/cmake3 /usr/bin/cmake

# get latest Kodi source from GitHub
RUN	cd $HOME \
	&& curl -LO https://github.com/xbmc/xbmc/archive/master.tar.gz \
	&& tar zxvf master.tar.gz

# install Kodi depencencies with Kodi's Unified Depends Build System 
RUN 	cd $HOME/xbmc-master/tools/depends \
	&& ./bootstrap \
	&& source /opt/rh/devtoolset-6/enable \
	&& ./configure --prefix=/opt/xbmc-deps \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C native \
		autoconf-native \
		automake-native \
		libtool-native \
		pkg-config-native \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target/libfmt CMAKE=/usr/bin/cmake PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target \
		freetype2 \
		libxml2 \
		fribidi \
	&& PKG_CONFIG_PATH=/opt/xbmc-deps/x86_64-linux-gnu-debug/lib/pkgconfig make -j$(getconf _NPROCESSORS_ONLN) -C target/fontconfig CONFIGURE='./configure --enable-libxml2 --prefix=/opt/xbmc-deps/x86_64-linux-gnu-native' \
	&& PKG_CONFIG_PATH=/opt/xbmc-deps/x86_64-linux-gnu-debug/lib/pkgconfig make -j$(getconf _NPROCESSORS_ONLN) -C target/libass PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target/taglib CMAKE=/usr/bin/cmake PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C native/swig-native PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target/libcdio-gplv3 PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target/tinyxml PREFIX=/usr/local \
	&& make -j$(getconf _NPROCESSORS_ONLN) -C target/sqlite3 PREFIX=/usr/local

RUN     cd $HOME/xbmc-master \
	&& sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' tools/depends/native/TexturePacker/src/TexturePacker.cpp \
	&& sed -i -E 's/(#include "ActiveAEFilter.h")/#define __STDC_FORMAT_MACROS\n#include <inttypes.h>\n\1/' xbmc/cores/AudioEngine/Engines/ActiveAE/ActiveAEFilter.cpp \
	&& sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' xbmc/music/MusicDatabase.cpp \
	&& sed -i 's/CURLOPT_ACCEPT_ENCODING/CURLOPT_ENCODING/' xbmc/filesystem/CurlFile.cpp \
	&& sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' xbmc/playlists/PlayListM3U.cpp \
	&& sed -i -E 's/(#include "GUIMediaWindow.h")/#define __STDC_FORMAT_MACROS\n\1/' xbmc/windows/GUIMediaWindow.cpp \
	&& sed -i -E 's/(#include "DVDDemuxVobsub.h")/#define __STDC_FORMAT_MACROS\n#include <inttypes.h>\n\1/' xbmc/cores/VideoPlayer/DVDDemuxers/DVDDemuxVobsub.cpp \
	&& curl https://raw.githubusercontent.com/mesa3d/mesa/master/include/EGL/{eglextchromium.h} --output '/usr/include/EGL/#1'

# build Kodi then install
RUN 	mkdir $HOME/kodi-build \
	&& cd $HOME/kodi-build \
	&& source /opt/rh/devtoolset-6/enable \
	&& source /opt/rh/python27/enable \
	&& PKG_CONFIG_PATH=/opt/xbmc-deps/x86_64-linux-gnu-debug/lib/pkgconfig cmake ../xbmc-master \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DENABLE_INTERNAL_FLATBUFFERS=1 \
		-DENABLE_INTERNAL_FSTRCMP=1 \
		-DENABLE_INTERNAL_RapidJSON=1 \
		-DENABLE_VDPAU=OFF \
		-DENABLE_VAAPI=OFF \
	&& cmake --build . -- VERBOSE=1 -j$(getconf _NPROCESSORS_ONLN) \
	&& make install

# remove build-only dependencies and intermediate files
RUN 	rm -rf	$HOME/xbmc-master \
		$HOME/xbmc-build \
		/opt/xbmc-deps \
	&& yum install -y yum-plugin-remove-with-leaves \
	&& yum remove -y --remove-leaves $BUILD_DEPS \
	&& yum clean all

# setup run scripts
COPY	run.sh /usr/local/bin/

RUN	echo /usr/local/lib > /etc/ld.so.conf.d/usr-local-lib.conf \
	&& ldconfig \
	&& echo -e 'source /opt/rh/python27/enable\nexec kodi' > /root/.xinitrc

CMD	[ "run.sh" ]
