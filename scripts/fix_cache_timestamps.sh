#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - fix_cache_timestamps.sh (时间戳跃迁魔法)
# 
# 📘【剧本背景】：
# 这是我们在深挖 `OpenWRT-CI` 源码时发现的“镇馆之宝”级别的隐藏黑科技！！
# 当 Github Actions 从云端金库（Cache）把文件下载解压到当前机器时，会让所有文件的“最后修改时间”自动变成当前时间。
# 但 OpenWrt 极其古板老派！它的 `make` 原理是：只要你源代码的时间，甚至是你刚解压出来的工具链的时间稍微不对付，
# 哪怕你缓存了 10G 的包，它也会把车床全砸了重造！导致你以为缓存了，实际上还是干烧了 2 小时！
#
# 🕵️‍♂️【作者神级意图与源码大解密】：
# 我们用 `touch` 魔法，把所有工具链的“免检合格证”（stamp 标记文件）的时间强制刷新为最新这一秒！
# 顺便在 `tmp` 里塞个 `.build` 字条告诉系统：“底层已经建好啦，我都查过了，别再自检了！” 
# 这样 OpenWrt 就会被完美骗过，直接跳过漫长且恐怖的 GCC 底层工具链建造，光速进入上层软路由插件的组装！
# 这正是我们能向您**“拍胸脯保证速度绝对起飞”**的终极底牌！
# =========================================================================================

echo "🪄 启动 OpenWrt 时间戳跃迁欺骗魔法..."

if [ -d "$GITHUB_WORKSPACE/openwrt/staging_dir" ]; then
  # 找出 staging_dir 下所有的 stamp（合格证文件夹），且排除了 target（因为目标产出是我们真的要变的），将里面的所有标记文件的时间戳全部刷新为未来！
  find "$GITHUB_WORKSPACE/openwrt/staging_dir" -type d -name "stamp" -not -path "*target*" | while read -r DIR; do
    find "$DIR" -type f -exec touch {} +
  done
  
  # 给系统大门贴个条子，表示环境是好的，跳过基础核心排雷自检
  mkdir -p $GITHUB_WORKSPACE/openwrt/tmp && echo "1" > $GITHUB_WORKSPACE/openwrt/tmp/.build
  echo "✅ 魔法释放完毕！底层交叉编译机器 (ToolChain) 重建检查已被完美跳过！进度条直达 80%！"
else
  echo "⚠️ 未发现上古时代遗留的工具链金库，本次为开荒时代的全新全量打底编译。"
fi
