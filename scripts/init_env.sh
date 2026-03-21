#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - init_env.sh
# =========================================================================================

export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -qq update
sudo -E apt-get -qq install -y --no-install-recommends \
  eatmydata ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 cargo ccache cdrkit-doc clang cmake cpio curl dejagnu device-tree-compiler \
  dos2unix ecj expect fastjar flex g++ g++-multilib gawk gcc gcc-multilib gettext \
  ghc git golang gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 \
  libelf-dev libfido2-dev libffi-dev libfuse-dev libglib2.0-dev libgmp-dev libgmp3-dev \
  libltdl-dev libltdl7 libmpc-dev libmpfr-dev libncurses-dev libncurses5-dev \
  libncursesw5-dev libpcre2-dev libpcre3-dev libpython3-dev libreadline-dev libssl-dev \
  libtext-unidecode-perl libtool libxml-libxml-perl libxml-namespacesupport-perl \
  libxml-sax-base-perl libxml-sax-perl libyaml-dev libz-dev lld llvm lrzsz luajit \
  luarocks make mkisofs msmtp nano ncurses-dev ninja-build openjdk-11-jdk p7zip \
  p7zip-full patch pkgconf pybind11-dev python2.7 python3 python3-dev python3-docutils \
  python3-pip python3-ply python3-pyelftools python3-setuptools qemu-utils re2c rsync \
  ruby-dev rustc scons sgml-base squashfs-tools subversion swig tcl-expect tcl8.6 \
  tex-common texinfo uglifyjs unzip upx-ucl vim wget wodim xmlto xxd zlib1g-dev zstd

sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
sudo timedatectl set-timezone "$TZ"

echo "🔍 全盘雷达扫描寻找空间最大数据盘..."
BEST_DISK=$(df -mP | awk 'NR>1 && $1 ~ /^\/dev\// && $6 != "/" && $6 !~ /boot/ && $4 > 20000 {print $6, $4}' | sort -nr -k2 | awk 'NR==1 {print $1}')

if [ -n "$BEST_DISK" ]; then
  echo "🎉 锁定极品额外数据盘: ${BEST_DISK}"
  export BEST_WORKDIR="${BEST_DISK}/workdir"
else
  export BEST_WORKDIR="/workdir"
fi

sudo mkdir -p "$BEST_WORKDIR"
sudo chown $USER:$GROUPS "$BEST_WORKDIR"
echo "WORK_DIR=$BEST_WORKDIR" >> $GITHUB_ENV
