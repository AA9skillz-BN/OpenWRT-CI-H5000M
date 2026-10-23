# 更新日志

本仓库的所有重要变更都会记录在此文件中。

## [2026-10-23] 修复初始化环境超时导致 CI 失败

### 背景

10-23 凌晨的 MTK-AUTO（run 39874026966，MEDIATEK-WIFI-YES / VIKINGYFY/immortalwrt）
在「Initialization Environment」步骤失败，而前两日同一 commit（e94bf52）构建均正常。

### 根因

runner 镜像 20261012 更新后，`apt full-upgrade` 待升级包增至 98 个，并新增
linux-azure 7.0 内核等 10 个包。下载与解包耗时超过 `apt_retry` 中统一的
`timeout 300`：日志显示三次尝试分别在 23:47:18 / 23:52:17 / 23:57:27 开始，
均于整 300 秒被杀，重试耗尽后步骤以 exit 1 结束。
此前同一构建该步骤耗时 5:12 / 5:46，本就接近 300 秒上限，属镜像更新后被推过阈值。

### 修复

- `.github/workflows/WRT-CORE.yml`：`apt_retry` 改为按命令传入超时
  （update 300s、install 900s、full-upgrade 1800s），避免慢速下载被误杀。
- 主机系统升级并非编译必需：`full-upgrade` 失败后执行
  `dpkg --configure -a` / `apt -f install` 修复状态并继续，不再中断 job。
- `init_build_environment.sh` 超时 600s → 1800s；三次均失败时显式 `exit 1`
  （原实现会静默跳过失败继续执行）。
- `timeout` 增加 `--kill-after=30` 防止残留进程，apt/dpkg 增加
  `--force-confdef` / `--force-confold` 非交互选项；`Acquire::Retries` 3 → 5。

### 验证

手动 workflow_dispatch 触发 MTK-AUTO（TEST=true，跳过编译）run 39888490893
全流程成功，`Initialization Environment` 耗时 4 分 42 秒、`full-upgrade`
一次通过。完整编译链路由次日定时构建覆盖验证。

## [2026-10-18] 切换构建源码：immortalwrt/immortalwrt@master → VIKINGYFY/immortalwrt@owrt

### 背景

此前全量定时（MTK-AUTO）与手动（WRT-BUILD）构建均基于官方
`immortalwrt/immortalwrt@master`。为与 VIKINGYFY 生态（构建脚手架与
`VIKINGYFY/packages` feed）保持同源、降低跨仓库版本漂移，现将底层源码
切换为 `VIKINGYFY/immortalwrt` 的 `owrt` 分支（commit 99c39ee）。

### 变更

- `MTK-AUTO.yml`：定时/自动构建 matrix 由 `SOURCE: [immortalwrt/immortalwrt]` /
  `BRANCH: [master]` 改为 `SOURCE: [VIKINGYFY/immortalwrt]` / `BRANCH: [owrt]`。
- `WRT-BUILD.yml`：手动触发默认 `SOURCE` 改为 `VIKINGYFY/immortalwrt`，默认
  `BRANCH` 改为 `owrt`，并同步更新分支选择说明（VIKINGYFY 用 owrt，immortalwrt 用 master）；
  官方 `immortalwrt/immortalwrt` 仍保留为可选源码，便于随时回退。
- `index.html`：落地页“固件源码”徽章与规格卡同步更新为 VIKINGYFY/immortalwrt@owrt。
- `README.md`：标题、ImmortalWrt 徽章、底层底包与维护周期中的构建源码表述同步更新为 VIKINGYFY/immortalwrt@owrt。
- 打包产物命名随之变化：`WRT_INFO`=VIKINGYFY、Release Tag 携带 `-owrt-` 后缀，
  与既有“按变体清晰区分”策略一致。
- packages feed 仍为 `VIKINGYFY/packages@main`（独立仓库，本次未改动），与源码同源。

### 影响

- 内核版本、插件清单、Release 标签将反映 VIKINGYFY/immortalwrt@owrt 的真实提交。
- 首次基于 owrt 分支构建将因源码变化而命中新的缓存键（ccache/toolchain），
  首次编译耗时可能增加，属预期行为。

## [2026-10-17] 修复全平台编译中断：移除 immortalwrt/packages 中过时的 miniupnpd 补丁

### 背景

10-17 凌晨的 MTK-AUTO（run 38979810271，MEDIATEK-WIFI-YES 变体）在
「Compile Firmware」步骤失败，前一日（10-16 合并前）构建正常。

### 根因

immortalwrt/packages 于 2026-10-16 03:02 UTC 执行「Merge Official Source」（dd29469e22），
将 openwrt/packages 上游 10-07 的 miniupnpd 2.3.11 升级合入。feed 自带的
`net/miniupnpd/patches/020-descr-filter-fix.patch`（权限行解析器重写）基于 2.3.9
编写，2.3.11 的 `upnppermissions.c/h` 已发生变动，导致 7 个 hunk 中 5 个
apply 失败、prepare 阶段即中断，miniupnpd(nftables) 编译失败并级联到
`make world` 退出。

经比对 miniupnpd 2.3.11 官方源码确认：该补丁的全部改动（`get_sep`/`get_ushort`/
`get_range`/`iseol` 解析器重写、`read_permission_line` 的 `const char *` 签名）
均已被上游吸收，补丁完全过时，删除无功能损失。与 H5000M-CI-Qmodem 同日
修复（commit 4e881f7）为同一问题。

### 修复

- `.github/workflows/WRT-CORE.yml`：Update Feeds 步骤后增加 workaround，
  若存在 `feeds/packages/net/miniupnpd/patches/020-descr-filter-fix.patch`
  则删除之。MTK-AUTO / WRT-BUILD 均复用 WRT-CORE，一处修复全覆盖。
  上游刷新补丁后可移除该 workaround。

### 验证

推送后手动 workflow_dispatch 触发 MTK-AUTO，观察 Compile Firmware 步骤
通过、固件产物生成。

## [2026-10-10]

### 变更

- **移除 MT5700M 依赖冗余组件**：应 issue #2 反馈，从固件配置中移除 `ubus-at-daemon`（默认串口与 MT5700M 不匹配、未被网页调用，纯占内存）与 `sms-tool` / `sms-tool_q`（短信工具，避免与上游拨号插件自带工具冲突）。后续构建的固件不再包含这三个包；`mt5700m-manager` 层面的功能改进（USB 3.0 自愈等）请反馈至上游 FAN789/luci-app-mt5700m。

### 变更文件

- `Config/GENERAL.txt` — 删除 `ubus-at-daemon`、`sms-tool`、`sms-tool_q` 三个配置项（commits 2a0c20e / 2f99243）

## [2026-09-25]

### 修复

- **sing-box 过时补丁导致构建失败**：今日（09-24）定时构建 `failure`，首个失败步骤为「编译固件」。根因为 `Scripts/Packages.sh` 克隆的 viking feed（`VIKINGYFY/packages`）中 sing-box 自带 `patches/100-fix-dns-tcp-close.patch` 与 `1.15.0_alpha8` 源码上下文不匹配（补丁引入的上游从未合入的 `HandleStreamDNSConnection`，而源码仍是 `HandleStreamDNSRequest`），`Build/Prepare` 阶段应用补丁报 `Patch failed!` 并 `Error 1`，整个固件编译中断。上游 `immortalwrt/packages` 的 sing-box 根本不携带该补丁也能正常构建，故判定为可安全移除的过时补丁。已在克隆 viking feed 后新增 `FIX_SINGBOX_STALE_PATCH`：仅当补丁内容含旧版标记 `HandleStreamDNSConnection` 时移除，若 VIKINGYFY 后续刷新补丁则自动跳过、不误删。

### 变更文件

- `Scripts/Packages.sh` — 新增 `FIX_SINGBOX_STALE_PATCH`（克隆 viking feed 后清理过时 sing-box 补丁）

## [2026-08-25]

### 新增

- **TTYD Web 终端**：全机型默认集成 [ttyd](https://github.com/tsl0922/ttyd) 网页命令行终端，LuCI「系统 → TTYD 终端」页面可在浏览器直接操作设备 Shell。`Config/GENERAL.txt` 新增并默认启用 `ttyd`、`luci-app-ttyd`、`luci-i18n-ttyd-zh-cn` 三个软件包。

### 变更文件

- `Config/GENERAL.txt` — 新增 TTYD Web 终端配置段（`ttyd` / `luci-app-ttyd` / `luci-i18n-ttyd-zh-cn`，均默认启用）
