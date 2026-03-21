#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - ccache_manager.sh
# 
# 📘【剧本背景】：
# Ccache 就像是老师批改过的卷子库（编译缓存金库）。下次遇到同样的题（代码），直接抄答案！
# 但是，每次编译成功后，我们都要把这堆新卷子锁进 GitHub 的保险箱。
# 为了让每次的保险箱只存最精华的“最新套题”（latest），必须要把以前那个保险箱彻底炸掉腾地方。
#
# 🕵️‍♂️【作者意图】：
# 这段代码极其暴力，它动用了 GitHub 官方大杀器工具 `gh api`（直接给 Github 核心服务器发指令），
# 不管三七二十一，先把云端所有叫 `*latest*` 和旧版错乱名字的保险箱全部从天界删掉！
# =========================================================================================

echo "🔍 正在执行极简化缓存策略：抹除云端所有存在的 ccache 缓存，确保新版能100%成功覆盖写入..."

# `gh api -X GET /repos/${REPOSITORY}/actions/caches?key=${CACHE_KEY}` 
# 这个长串，就像是对 GitHub 云端大喊：把叫 “latest” 的保险箱给我交出来！
# `jq -r '.actions_caches[].id'`：只从交出来的信息堆里挑出它长长的乱码“死刑执行号（id）”。
# `xargs -I {} ... -X DELETE ... {}`：端起机关枪，对着那个死刑号执行“抹除命令（DELETE）”！
# `|| true`：哪怕没找到惹它报错，也不许停（因为我们要的就是它死）。
gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?key=${RUNNER_OS}-openwrt-ccache-latest \
  | jq -r '.actions_caches[].id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
# 以防万一，顺手剿灭以前残留的所有带奇怪后缀名（以前生成的乱七八糟名字）的老旧怪胎
gh api -X GET /repos/${GITHUB_REPOSITORY}/actions/caches?per_page=100 \
  | jq -r '.actions_caches[] | select(.key | startswith("${RUNNER_OS}-openwrt-ccache-")) | .id' \
  | awk '{if ($1) system("gh api -X DELETE /repos/'${GITHUB_REPOSITORY}'/actions/caches/" $1)}' || true
  
echo "🎉 旧王座已被彻底清空！云端现在洁净如纸！"
