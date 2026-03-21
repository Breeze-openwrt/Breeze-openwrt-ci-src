#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - init_env.sh
# 
# 📘【剧本背景】：
# “工欲善其事，必先利其器”。在做这桌满汉全席（OpenWrt 固件）前，
# 我们得确保厨房里（Ubuntu）各种神兵利器都准备好了（编译器、解压器、各种 C语言底层依赖库）。
# 
# 🕵️‍♂️【作者意图与性能狂魔奥义】：
# 作者将冗长的 apt 依赖表合为一行，彻底解放服务器 I/O 空窗期（不用每次单独启动读取）。
# 并且植入了“异星寻宝雷达算法”，这是防爆缸的神来之笔！它会在云主机挂载的所有块设备盘符中，
# 精准找到容量 > 20GB 且不是主盘的数据盘，把工作区设在那里，避免系统和数据挤在一起导致 I/O 堵死。
# =========================================================================================

# `export` = 向全国广播大喇叭，把这个变量变成所有子程序都能读取的环境变量。
# `DEBIAN_FRONTEND=noninteractive` = “机器人面瘫模式”。这就相当于高速公路上的 ETC，
# 当安装软件时如果不加这句，系统可能突然弹框问“大爷你要设为默认吗？按 Y 还是 N”。这就卡死流水线了。
export DEBIAN_FRONTEND=noninteractive

# `sudo -E` = `sudo` 是超级管理员，而 `-E` 代表"保留当前小红帽的环境变量"，不要切换身份后失忆。
# `apt-get -qq update` = `apt` 是软件商店下载器，`-qq` 代表“极其极其安静”，别在屏幕上刷几万行无用弹幕闪瞎狗眼，`update` 是去云端拉取最新软件名字单子。
sudo -E apt-get -qq update

# `install -y` = 无脑点头，逢问必"Yes" 允许安装。
# `--no-install-recommends` = “拒绝流氓推销”。只要核心部件，不要那些没用的说明书和附带全家桶（能减掉好几分钟时间体积）！
# 后面的 `ack antlr3...` 等一大串，就是咱们编译需要的大量剪刀菜刀（例如 gcc编译器、python套件、git工具等）。
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

# `autoremove --purge` = 骨灰级清理：把那些买东西送的废旧包装盒、过期无用依赖一并彻底粉碎掉。
sudo -E apt-get -qq autoremove --purge
# `clean` = 擦黑板：清扫下载到本地的 apt 原生包裹文件缓存区。
sudo -E apt-get -qq clean

# `timedatectl set-timezone` = 调表。防止你在东八区早上生成固件，出来一看穿越到了昨晚美国的标签。
sudo timedatectl set-timezone "$TZ"

# ==================== 💎 性能狂魔：异星寻宝系统（硬盘智能调度）====================
echo "🔍 正在进行全盘雷达扫描，寻找空间最大、性能最顶的非系统数据挂载盘..."

# 【超级黑客级算法解析 - BEST_DISK 探雷波】：
# `df -mP`：列出所有磁盘空间详情，且强行以 MB 为单位对齐 (-P 是防断行的格式化工具)。
# `awk`：数据切片大师！
# `$1 ~ /^\/dev\//`：第1列(磁盘名)必须满足是来自底层的正经块设备 /dev/xxx（排雷：剔除各种伪造的虚拟内存盘）。
# `$6 != "/" && $6 !~ /boot/`：第6列(挂载点)绝对不能是 `/` (电脑老大的床单绝对不能划) 且不能包含 `boot` 这种开机要命盘。
# `$4 > 20000`：第4列(剩余可用空间) 必须严格大喊其满足 20000 MB （即 20GB），这叫安全红线！再小绝对引发爆缸血案死区。
# `sort -nr -k2`：把合格的优胜勇士们，按剩余空间的数字（-n）从大到小倒序排列（-r），就靠那第2个数值拼高低！
# `awk 'NR==1 {print $1}'`：NR==1 (Number of Record 第一号)，也就是咱们就揪出金字塔尖、排名第一那位盘王的名字！
BEST_DISK=$(df -mP | awk 'NR>1 && $1 ~ /^\/dev\// && $6 != "/" && $6 !~ /boot/ && $4 > 20000 {print $6, $4}' | sort -nr -k2 | awk 'NR==1 {print $1}')

# `if [ -n "$BEST_DISK" ]` 判断 `BEST_DISK` 这个字符串变量是不是不为空（是不是成功抓到了肉鸡盘）。
if [ -n "$BEST_DISK" ]; then
  echo "🎉 雷达锁定！发掘出一块满足编译大容量需求的极品额外数据盘: ${BEST_DISK}，I/O 起飞！"
  export BEST_WORKDIR="${BEST_DISK}/workdir"
else
  # 如果很不幸，所有外置数据盘都被前面占满或者干脆没有，系统会自动回退到在系统根目录当牛做马。
  echo "⚠️ 未探知到符合空间安全红线（>20GB）的额外数据副盘。启用最高性能的原生大容量主干系统盘代替..."
  export BEST_WORKDIR="/workdir"
fi

echo "🚀 最终裁定的核心编译军工厂坐标为：$BEST_WORKDIR"

# `mkdir -p` = 无脑破局建房子。不管前面几级祖宗目录存不存在，一路造出来。
sudo mkdir -p "$BEST_WORKDIR"
# `chown` = Change Owner 换地契。这块肥肉既然是用上帝账号（sudo）划出来的，平民账户（咱们流水线普通工人）进不去！所以必须给它上当前工人 `$USER:$GROUPS` 自己的房本名，后续干活才不报错。
sudo chown $USER:$GROUPS "$BEST_WORKDIR"

# 最后最最关键的一步，这也是与 YAML 对接的点：
# 把它通过 `echo "xxx=yyy" >> $GITHUB_ENV` 写进“GitHub全球天书”，让这条流水线之后所有后续动作都知道要去哪儿找这块宝地！
echo "WORK_DIR=$BEST_WORKDIR" >> $GITHUB_ENV
