#!/bin/bash -e

WORKDIR=$PWD/Workdir
OUPUTDIR=$WORKDIR/Builds

mkdir -p $WORKDIR $OUTPUTDIR

cd $WORKDIR

wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r29-linux.zip
unzip ndk.zip
cd android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/sysroot

for patches in 1.patch 2.patch 3.patch 4.patch 5.patch 6.patch 7.patch 8.patch 9.patch 10.patch stdlib.h.patch sys-cdefs.h.patch sys-time.h.patch
