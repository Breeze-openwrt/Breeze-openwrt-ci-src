# 修复 `/workdir/firmware` 目录不存在错误

## 问题背景

CI 构建在 "Organize ALL output files" 步骤中报错：
```
du: cannot access '/workdir/firmware': No such file or directory
Error: Process completed with exit code 1.
```

## 根因分析

问题出在 [build-ALL-immortalwrt.yml](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml) 第 350-362 行。

**核心矛盾**：`du -sh ${{ env.FIRMWARE }}` 使用了 GitHub Actions 的 `${{ }}` 表达式语法。这种语法会在步骤**启动之前**就被预先解析为字面值。而此时 `FIRMWARE` 环境变量仍然是第 80 行定义的初始值 `/workdir/firmware`，第 361 行的更新 `echo "FIRMWARE=..." >> $GITHUB_ENV` 来得太晚了。

> [!CAUTION]
> `${{ env.XXX }}` 是**编译时**求值，`$XXX` 是**运行时**求值。在同一个 `run:` 块中先 `du` 后 `echo >> $GITHUB_ENV` 更新变量，前面的 `${{ }}` 表达式不可能读到后面的更新。

```yaml
# 第 80 行 - 初始值
FIRMWARE: /workdir/firmware

# 第 355-361 行 - 执行顺序
mkdir -p $GITHUB_WORKSPACE/firmware            # ✅ 目录在 $GITHUB_WORKSPACE 下创建
cp -r openwrt/bin/targets/*/*/*.* ...           # ✅ 固件拷贝到正确位置
du -sh ${{ env.FIRMWARE }}                     # ❌ 被预解析为 /workdir/firmware (初始值)
echo "FIRMWARE=$GITHUB_WORKSPACE/firmware" >> $GITHUB_ENV  # 太晚了！
```

## 提议修改

### CI 工作流

#### [MODIFY] [build-ALL-immortalwrt.yml](file:///d:/prj/mihhawork/Breeze-openwrt-ci-src/.github/workflows/build-ALL-immortalwrt.yml)

**修复策略**：调整第 354-362 行中 `du` 和 `FIRMWARE` 赋值的顺序，并将 `du` 改用 shell 变量 `$FIRMWARE`（运行时求值），而非 `${{ env.FIRMWARE }}`（编译时求值）。

```diff
         run: |
           mkdir -p $GITHUB_WORKSPACE/firmware
           cp -r openwrt/bin/targets/*/*/*.* $GITHUB_WORKSPACE/firmware/ 2>/dev/null || true
           rm -rf $GITHUB_WORKSPACE/firmware/packages
+          # 先更新 FIRMWARE 变量，供后续步骤使用
+          echo "FIRMWARE=$GITHUB_WORKSPACE/firmware" >> $GITHUB_ENV
           echo "📊 最终生成的全量固件总体积："
-          du -sh ${{ env.FIRMWARE }}
-          echo "FIRMWARE=$GITHUB_WORKSPACE/firmware" >> $GITHUB_ENV
+          du -sh $GITHUB_WORKSPACE/firmware
           echo "status=success" >> $GITHUB_OUTPUT
```

## 验证计划

### 手动验证
- 推送修改后触发 CI 构建，检查 "Organize ALL output files" 步骤不再报 `du: cannot access` 错误，且能正确打印固件体积。
