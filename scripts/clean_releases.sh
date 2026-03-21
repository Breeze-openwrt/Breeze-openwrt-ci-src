#!/bin/bash

# =========================================================================================
# 🎓【初二小白课堂：源码阅读与赏析】 - clean_releases.sh
# =========================================================================================

echo "⚠️ 启动流水线僵尸记录绞肉机..."
gh run list --limit 500 --json databaseId -q '.[].databaseId' | tail -n +36 | xargs -r gh run delete || true

if [ "$UPLOAD_RELEASE" == "true" ]; then
  echo "⚠️ 启动废弃固件旧版发布清除仪..."
  tags=$(gh release list -L 100 | awk -F '\t' '{print $1}' | tail -n +31)
  if [ -n "$tags" ]; then
    for tag in $tags; do
      gh release delete "$tag" --cleanup-tag -y || true
    done
  fi
fi
