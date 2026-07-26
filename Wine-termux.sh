#!/bin/bash -e

WORKDIR=$PWD/Workdir
OUTPUTDIR=$WORKDIR/Builds

mkdir -p $WORKDIR $OUTPUTDIR

cd $WORKDIR

wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r29-linux.zip
unzip ndk.zip
cd android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot

for patches in 1.patch 2.patch 3.patch 4.patch 5.patch 6.patch 7.patch 8.patch 9.patch 10.patch stdlib.h.patch sys-cdefs.h.patch sys-time.h.patch syslog.patch time.h.patch unistd.h.patch utmp.h.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/termux-packages/refs/heads/master/ndk-patches/29/"$patches"
patch -p1 -i "$patches"
done

cd ../../../../../..

git clone --depth=1 --recursive https://gitlab.winehq.org/wine/wine.git

cd wine

for patches in 0001-fix-paths.patch 0002-no-pthread_mutexattr_setprotocol.patch 0003-fix-socket-ipx.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/tur/refs/heads/master/tur/wine-devel/"$patches"
patch -p1 -i "$patches"
done

chmod +x configure
./configure \
--prefix="$OUTPUTDIR" \
--with-opengl \
--with-vulkan \
--enable-nls \
--disable-tests \
--without-alsa \
--with-pulse \
--without-capi \
--without-coreaudio \
--without-cups \
--without-dbus \
--with-fontconfig \
--with-freetype \

