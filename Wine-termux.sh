#!/bin/bash -e
set -e pipefail

WORKDIR=$PWD/Workdir
OUTPUTDIR=$WORKDIR/Builds

mkdir -p $WORKDIR $OUTPUTDIR

cd $WORKDIR

wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r29-linux.zip &> /dev/null
unzip ndk.zip &> /dev/null
wget -O mingw.tar.xz https://github.com/mstorsjo/llvm-mingw/releases/download/20260616/llvm-mingw-20260616-ucrt-ubuntu-22.04-x86_64.tar.xz &> /dev/null # The Standard MINGW package doesn't have arm64ec 
tar -xf mingw.tar.xz &> /dev/null
export PATH="$WORKDIR/llvm-mingw-20260616-ucrt-ubuntu-22.04-x86_64/bin:$PATH"

cd android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot &> /dev/null

for patches in 1.patch 2.patch 3.patch 4.patch 5.patch 6.patch 7.patch 8.patch 9.patch 10.patch stdlib.h.patch sys-cdefs.h.patch sys-time.h.patch syslog.patch time.h.patch unistd.h.patch utmp.h.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/termux-packages/refs/heads/master/ndk-patches/29/"$patches"
patch -p1 -i "$patches"
done

cd ../../../../../..

export NDK=$WORKDIR/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin

git clone --depth=1 --recursive https://gitlab.winehq.org/wine/wine.git

cd wine

wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/refs/heads/main/Extras/patch-fixer.py

for patches in 0001-fix-paths.patch 0002-fix-defines.patch 0003-fix-socket-ipx.patch 0004-no-pthread_mutexattr_setprotocol.patch 0005-use-__builtin_ffs.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/tur/refs/heads/master/tur/wine-stable/"$patches"
python3 patch-fixer.py "$patches"
done

export CROSSCC="arm64ec-w64-mingw32-clang"
export CROSSCXX="arm64ec-w64-mingw32-clang++"
export CC=$NDK/aarch64-linux-android30-clang
export CXX=$NDK/aarch64-linux-android30-clang++

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
--without-wayland \
--with-x \
--without-usb \
--with-gstreamer \
--with-pthread \
--with-xcomposite \
--enable-win64 \
--enable-archs=arm64ec,aarch64,i386 \
--with-xcursor \
--with-xfixes \
--with-mingw=clang \
--without-xinerama \
--with-xinput \
--with-xinput2 \
--with-xrander \
--with-xrender \
--without-xshape \
--without-xshm \
--without-xxf86vm \
--without-gettext \
--with-krb5 \
--with-sdl \
--enable-wineandroid_drv=no \
--disable-amd_args_x64 \
--host=aarch64-linux-android \
--build=x86_64-linux-gnu


make -j$(nproc)
make install

cd $OUTPUTDIR
tar -cJf wine.tar.xz bin lib share include
