# 修复 CI 固件目录路径不存在错误

## 修改内容

修改了 [build-ALL-immortalwrt.yml](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml#L350-L366) 中 "Organize ALL output files" 步骤：

1. **将 `du -sh ${{ env.FIRMWARE }}` 改为 `du -sh $GITHUB_WORKSPACE/firmware`** — 避免 GitHub Actions 编译时表达式读到旧初始值 `/workdir/firmware`
2. **将 `echo "FIRMWARE=..." >> $GITHUB_ENV` 提前到 `du` 之前** — 确保后续步骤能正确解析 `${{ env.FIRMWARE }}`

render_diffs(file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml)

## 验证方式

推送修改后触发 CI 构建，确认 "Organize ALL output files" 步骤不再报 `du: cannot access '/workdir/firmware'` 错误。
