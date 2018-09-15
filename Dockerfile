FROM centos:6.10

# install basic X Window System
RUN yum install -y \
		dbus \
		dbus-x11 \
		udev \
		xorg-x11-server-Xorg \
		xorg-x11-xinit \
		xterm \
	&& echo 'exec xterm' > /root/.xinitrc

RUN cd /etc/yum.repos.d \
	# install gcc 4.9 and python 2.7 from Software Collections
	&& curl -O http://copr-fe.cloud.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo \
	&& yum install -y centos-release-scl-rh \
	&& yum install -y \
		scl-utils \
		devtoolset-3-gcc \
		devtoolset-3-gcc-c++ \
		python27 \
	&& source /opt/rh/devtoolset-3/enable \
	&& source /opt/rh/python27/enable \
	\
	# build Kodi https://github.com/xbmc/xbmc/blob/master/docs/README.Linux.md
	&& yum install -y epel-release \
	&& yum install -y \
		git-core \
		libuuid-devel \
		patch \
		cmake3 \
		lzo-devel \
		libpng-devel \
		giflib-devel \
		libjpeg-turbo-devel \
		libxml2-devel \
		libass-devel \
		libcdio-devel \
		expat-devel \
		libcurl-devel \
		openssl-devel \
		pcre-devel \
		sqlite-devel \
		tinyxml-devel \
		mesa-libGL-devel \
		mesa-libGLU-devel \
		mesa-libEGL-devel \
		libXrandr-devel \
		java-1.8.0-openjdk \
		# swig \
		yasm \
		libtool \
		gettext \
		ghostscript \
		byacc \
	&& ln -s /usr/bin/cmake3 /usr/bin/cmake \
	&& git clone https://github.com/taglib/taglib.git \
		&& cd taglib \
		&& cmake . \
		&& make \
		&& make install \
		&& cd .. \
	&& git clone https://github.com/swig/swig.git \
		&& cd swig \
		&& ./autogen.sh \
		&& ./configure \
		&& make \
		&& make install \
		&& cd .. \
	&& git clone https://github.com/xbmc/xbmc $HOME/kodi \
	&& cd $HOME/kodi \
	&& sed -i -E 's/(#include <inttypes.h>)/#define __STDC_FORMAT_MACROS\n\1/' tools/depends/native/TexturePacker/src/TexturePacker.cpp \
	&& sed -i -E 's/(#include "ActiveAEFilter.h")/#define __STDC_FORMAT_MACROS\n#include <inttypes.h>\n\1/' xbmc/cores/AudioEngine/Engines/ActiveAE/ActiveAEFilter.cpp \
	&& make -C tools/depends/target/crossguid PREFIX=/usr/local \
	&& make -C tools/depends/target/flatbuffers PREFIX=/usr/local \
	&& make -C tools/depends/target/libfmt PREFIX=/usr/local  \
	&& mkdir $HOME/kodi-build \
	&& cd $HOME/kodi-build \
	&& cmake ../kodi \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DENABLE_INTERNAL_FSTRCMP=1 \
		-DENABLE_INTERNAL_RapidJSON=1 \
		# NVIDIA accelaration want to enable
		-DENABLE_VDPAU=OFF \
		-DENABLE_VAAPI=OFF \
	&& cmake --build . -- VERBOSE=1 -j$(getconf _NPROCESSORS_ONLN) \
	&& usermod -a -G input,video 1000 \
	&& make install

COPY services.sh /usr/local/bin/

CMD [ "/usr/local/bin/services.sh" ]
