#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not found directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"

UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

#UPDATE_PACKAGE "athena-led" "unraveloop/JDC-AX6600-Athena-LED-Controller" "main"
UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "axonhub gecoosac sing-box luci-app-homeproxy luci-app-timewol luci-app-wolplus luci-app-wolultra"

# 2026-10-23 移除 qmodem（FUjr/QModem）clone：
# luci-app-mt5700m 自 3.0.0 起以自有 C 程序 mt5700m-transport 完整覆盖模组管理
# （AT 串口/TCP、短信、流量、健康检查），运行时不再依赖 QModem 服务；
# 且 QModem 与 luci-app-mt5700m 会争抢同一 AT 串口，并存存在误操作风险。
# 本固件 GENERAL.txt 从未启用 luci-app-qmodem，移除 clone 不影响产物，
# 仅减少每次构建的 clone 耗时与 package 树体积。如需恢复，取消下一行注释：
#UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"

# ===== sing-box 过时补丁清理（2026-09-24 定时构建失败根因）=====
# VIKINGYFY/packages 的 sing-box 自带 patches/100-fix-dns-tcp-close.patch，它是针对
# 旧版 sing-box 的反向移植（引入上游从未合入的 HandleStreamDNSConnection）。当 feed 把
# sing-box 升到 1.15.0_alpha8 后，该补丁上下文已与上游源码（仍是 HandleStreamDNSRequest）
# 不匹配，OpenWrt 在 Build/Prepare 阶段应用补丁报 “Patch failed!” 并 Error 1，
# 进而令整个固件编译中断（今日定时构建失败即此因）。上游 immortalwrt/packages 的 sing-box
# 根本不携带该补丁也能正常构建，故这里在补丁确为旧版（内容含 HandleStreamDNSConnection）
# 时移除它，恢复构建。若 VIKINGYFY 后续刷新该补丁为适配新源码的版本，本规则因标记不匹配
# 而自动跳过，不会误删新版补丁。
FIX_SINGBOX_STALE_PATCH() {
	local PATCH="./packages/sing-box/patches/100-fix-dns-tcp-close.patch"
	[ -f "$PATCH" ] || { echo "sing-box: 无 100-fix-dns-tcp-close.patch，跳过"; return 0; }
	# 仅当补丁仍为旧版（引入未合入上游的 HandleStreamDNSConnection）时才移除
	if grep -q "HandleStreamDNSConnection" "$PATCH"; then
		rm -f "$PATCH"
		echo "sing-box: 移除过时补丁 100-fix-dns-tcp-close.patch（与 1.15.0_alpha8 源码不匹配）"
	else
		echo "sing-box: 100-fix-dns-tcp-close.patch 已非旧版，保留"
	fi
}
FIX_SINGBOX_STALE_PATCH

UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"

# FAN789 插件
UPDATE_PACKAGE "luci-app-h5000m-fancontrol" "FAN789/luci-app-h5000m-fancontrol" "main"
UPDATE_PACKAGE "luci-app-mt5700m" "FAN789/luci-app-mt5700m" "main"
UPDATE_PACKAGE "luci-app-h5000m-netmode" "FAN789/luci-app-h5000m-netmode" "main"

# ===== luci-app-mt5700m 克隆结果校验与版本记录（2026-10-23）=====
# 该仓库顶层无 Makefile，由 luci-app-mt5700m/ 与 mt5700m-transport/ 两个子目录
# 提供包定义（immortalwrt 的 include/scan.mk 以 SCAN_DEPTH=5 扫描 package/ 树，
# 二级子目录可被正常识别，无需平铺）。这里在上游仓库结构调整时尽早失败，
# 并把版本号写入 GITHUB_ENV 供 Release Notes 引用。
MT5700M_APP_DIR="./luci-app-mt5700m/luci-app-mt5700m"
MT5700M_TP_DIR="./luci-app-mt5700m/mt5700m-transport"
if [ -f "$MT5700M_APP_DIR/Makefile" ] && [ -f "$MT5700M_TP_DIR/Makefile" ]; then
	MT5700M_APP_VER=$(sed -n 's/^PKG_VERSION:=//p' "$MT5700M_APP_DIR/Makefile" | head -1)
	MT5700M_TP_VER=$(sed -n 's/^PKG_VERSION:=//p' "$MT5700M_TP_DIR/Makefile" | head -1)
	MT5700M_INFO="app ${MT5700M_APP_VER} / transport ${MT5700M_TP_VER}"
	echo "luci-app-mt5700m version: $MT5700M_INFO"
	[ -n "${GITHUB_ENV:-}" ] && echo "MT5700M_VERSION=$MT5700M_INFO" >> "$GITHUB_ENV"
else
	echo "ERROR: FAN789/luci-app-mt5700m 仓库结构异常：未找到 $MT5700M_APP_DIR/Makefile 或 $MT5700M_TP_DIR/Makefile" >&2
	exit 1
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
