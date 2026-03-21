#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - ccache_manager.sh (极简大成版)
# 
# 📘【剧本背景】：
# 老大指示：名字不宜花里胡哨，大道流转，万法归一。
# 既然已经是单容器串行同源工厂，那缓存收纳盒的名字就稳稳地叫：
# `Linux-openwrt-ccache-latest` 即可！
# =========================================================================================

echo "🔍 正在执行缓存换血出清：抹除云端大库 [ccache-latest] 旧缓存箱，为新鲜出炉的金丹腾空位..."

gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?key=${RUNNER_OS}-openwrt-ccache-latest \
  | jq -r '.actions_caches[].id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?per_page=100 \
  | jq -r '.actions_caches[] | select(.key | startswith("${RUNNER_OS}-openwrt-ccache-")) | .id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
echo "🎉 云端旧的 latest 王座已被彻底清空！无极生太极，缓存永存！"
