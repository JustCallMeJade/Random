#!/usr/bin/env bash -e

workdir="$(pwd)/workdir"
install_dir="$workdir/install_dir"

mkdir -p "$workdir" && mkdir -p "$install_dir"

cd "$workdir"

dnf update > /dev/null -y && dnf builddep mesa > /dev/null -y
dnf install pkg-config wget cmake python3 git > /dev/null -y

git clone --depth 1 https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa

wget -O zink-experimental-patch.py https://raw.githubusercontent.com/JustCallMeJade/Extras/refs/heads/main/Extras/Py-Patches/zink-experimental.py

python3 zink-experimental-patch.py

meson setup build --prefix "$install_dir" -Dplatforms=x11 -Dglx=xlib -Dopengl=true -Dgles1=disabled -Degl=disabled -Dgles2=disabled -Dstrip=true -Dgallium-drivers=zink -Dvulkan-drivers=

ninja -C build -j$(nproc) install

exit 0
