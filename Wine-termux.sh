#!/bin/bash -e
set -e pipefail

WORKDIR=$PWD/Workdir

mkdir -p $WORKDIR $OUTPUTDIR

cd $WORKDIR

mkdir Builds

wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r29-linux.zip &> /dev/null
unzip ndk.zip &> /dev/null
wget -O mingw.tar.xz https://github.com/mstorsjo/llvm-mingw/releases/download/20260616/llvm-mingw-20260616-ucrt-ubuntu-22.04-x86_64.tar.xz &> /dev/null # The Standard MINGW package doesn't have arm64ec 
tar -xf mingw.tar.xz &> /dev/null
wget -O termuxfs.tar https://github.com/GameNative/termux-on-gha/releases/download/build-20260218/termuxfs-aarch64.tar &> /dev/null
tar -xf termuxfs.tar
export PATH="$WORKDIR/llvm-mingw-20260616-ucrt-ubuntu-22.04-x86_64/bin:$PATH"

cd android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot

for patches in 1.patch 2.patch 3.patch 4.patch 5.patch 6.patch 7.patch 8.patch 9.patch 10.patch stdlib.h.patch sys-cdefs.h.patch sys-time.h.patch syslog.patch time.h.patch unistd.h.patch utmp.h.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/termux-packages/refs/heads/master/ndk-patches/29/"$patches"
patch -p1 -i "$patches"
done

cd ../../../../../..

export NDK=$WORKDIR/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin

git clone --recursive https://github.com/ValveSoftware/wine

cd wine

chmod +x autogen.sh
./autogen.sh

wget https://raw.githubusercontent.com/JustCallMeJade/Turnip_drivers_adreno/refs/heads/main/Extras/patch-fixer.py

for patches in 0001-fix-paths.patch 0002-fix-defines.patch 0003-fix-socket-ipx.patch 0004-no-pthread_mutexattr_setprotocol.patch 0005-use-__builtin_ffs.patch 9998-fix-winegcc-build-target.patch 9999-fix-winebuild-as-type.patch; do
wget https://raw.githubusercontent.com/JustCallMeJade/tur/refs/heads/master/tur/wine-stable/"$patches"
python3 patch-fixer.py "$patches"
done

for patch in $(find ../../patches/arm64ec -name "*.patch" | sort -V); do
    python3 patch-fixer.py "$patch"
done

for patch in $(find ../../patches/common -name "*.patch" | sort -V); do
    python3 patch-fixer.py "$patch"
done

for directories in ./dll/ntdll/unix/ ./server/; do
cp ../../shm_utils/shm_utils.h "$directories"
done

chmod +x configure

mkdir wine-tools

cd wine-tools

../configure --without-x --without-gstreamer --without-vulkan --without-wayland
make -j$(nproc) __tooldeps__ nls/all

cd ..

export CROSSCC="arm64ec-w64-mingw32-clang"
export CROSSCXX="arm64ec-w64-mingw32-clang++"
export CC="$NDK/aarch64-linux-android28-clang"
export CXX="$NDK/aarch64-linux-android28-clang++"
export AR="$NDK/llvm-ar"
export RANLIB="$NDK/llvm-ranlib"
export STRIP="$NDK/llvm-strip"
export NM="$NDK/llvm-nm"
export deps="$WORKDIR/data/data/com.termux/files/usr"

chmod +x $WORKDIR/../android-sysvshem/build.sh

bash $WORKDIR/../android-sysvshem/build.sh

export PKG_CONFIG_LIBDIR=$deps/lib/pkgconfig:$deps/share/pkgconfig
export ACLOCAL_PATH=$deps/lib/aclocal:$deps/share/aclocal
export FREETYPE_CFLAGS="-I$deps/include/freetype2"
export PULSE_CFLAGS="-I$deps/include/pulse"
export PULSE_LIBS="-L$deps/lib/pulseaudio -lpulse"
export SDL2_CFLAGS="-I$deps/include/SDL2"
export SDL2_LIBS="-L$deps/lib -lSDL2"
export X_CFLAGS="-I$deps/include/X11"
export X_LIBS="-landroid-sysvshm"
export GSTREAMER_CFLAGS="-I$deps/include/gstreamer-1.0 -I$deps/include/glib-2.0 -I$deps/lib/glib-2.0/include -I$deps/glib-2.0/include -I$deps/lib/gstreamer-1.0/include"
export GSTREAMER_LIBS="-L$deps/lib -lgstgl-1.0 -lgstapp-1.0 -lgstvideo-1.0 -lgstaudio-1.0 -lglib-2.0 -lgobject-2.0 -lgio-2.0 -lgsttag-1.0 -lgstbase-1.0 -lgstreamer-1.0"
export FFMPEG_CFLAGS="-I$deps/include/libavutil -I$deps/include/libavcodec -I$deps/include/libavformat"
export FFMPEG_LIBS="-L$deps/lib -lavutil -lavcodec -lavformat"
export DLLTOOL="$WORKDIR/llvm-mingw-w64-ucrt-2026016-ubuntu-22.04-x86_64/bin/llvm-dlltool"
export CPPFLAGS="-I$deps/include --sysroot=$NDK/../sysroot"
export CFLAGS="-Wno-declaration-after-statement"
export CXXFLAGS="-Wno-declaration-after-statement"
export LDFLAGS="-L$deps/lib"

./configure \
--prefix="$PWD/../Builds" \
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
--without-fontconfig \
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
--with-xrandr \
--with-xrender \
--without-xshape \
--without-xshm \
--without-xxf86vm \
--without-gettext \
--without-krb5 \
--with-sdl \
--enable-wineandroid_drv=no \
--disable-amd_args_x64 \
--host=aarch64-linux-android28 \
--with-wine-tools=./wine-tools

make -j$(nproc)
make install

cd $OUTPUTDIR
tar -cJf wine.tar.xz bin lib share include
