# 更新日志

本仓库的所有重要变更都会记录在此文件中。

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
