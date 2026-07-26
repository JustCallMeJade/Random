#!/bin/bash -e

WORKDIR=$PWD/Workdir
OUTPUTDIR=$WORKDIR/Builds

mkdir -p $WORKDIR $OUTPUTDIR

cd $WORKDIR

wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r29-linux.zip &> /dev/null
unzip ndk.zip
cd android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot &> /dev/null

for patches in 1.patch 2.patch 3.patch 4.patch 5.patch 6.patch 7.patch 8.patch 9.patch 10.patch stdlib.h.patch sys-cdefs.h.patch sys-time.h.patch syslog.patch time.h.patch unistd.h.patch utmp.h.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/termux-packages/refs/heads/master/ndk-patches/29/"$patches"
patch -p1 -i "$patches"
done

cd ../../../../../..

export NDK=$WORKDIR/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin

git clone --depth=1 --recursive https://gitlab.winehq.org/wine/wine.git

cd wine

for patches in 0001-fix-paths.patch 0002-no-pthread_mutexattr_setprotocol.patch 0003-fix-socket-ipx.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/tur/refs/heads/master/tur/wine-devel/"$patches"
patch -p1 -i "$patches"
done

export CROSSCC="x86_64-w64-mingw32-gcc"
export CROSSCXX="x86_64-w64-mingw32-g++"
export C=$NDK/x86_64-linux-android28-clang
export CXX=$NDK/x86_64-linux-android28-clang++

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
--without-opencl \
--without-osmesa \
--without-oss \
--with-wayland \
--with-x \
--without-usb \
--with-gstreamer \
--with-pthread \
--with-xcomposite \
--enable-win64 \
--enable-archs=x86_64,i386 \
--with-xcursor \
--with-xfixes \
--with-mingw \
--without-xinerama \
--with-xinput \
--with-xinput2 \
--with-xrander \
--with-xrender \
--without-xshape \
--without-xshm \
--without-xxf86vm

make -j$(nproc)
make install
