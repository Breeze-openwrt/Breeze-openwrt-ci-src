#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - clean_ubuntu.sh
# =========================================================================================

echo "📊 强力拆迁前系统总可用空间："
df -hT

echo "🧨 警告：正在引爆云端的旧有原厂巨兽建筑..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
sudo rm -rf /usr/local/share/boost /usr/share/swift /usr/lib/jvm /usr/share/miniconda /usr/local/share/chromium
sudo docker image prune --all --force

echo "🎉 新世界建筑彻底清除完毕，已达到物理理论上的清理极值！耗时仅几秒！"
df -hT
