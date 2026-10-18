<div align="center">

# 🚀 Hiveton H5000M (MT5700M) 定制固件说明书

**基于 ImmortalWrt 主线（VIKINGYFY/immortalwrt @ owrt）源码 · 专为联发科 Filogic 平台 5G CPE 打造的高性能全功能固件**

[![ImmortalWrt](https://img.shields.io/badge/ImmortalWrt-VIKINGYFY%2Fowrt-00A0D0.svg?logo=openwrt&logoColor=white&style=flat-square)](https://github.com/VIKINGYFY/immortalwrt)
[![Platform](https://img.shields.io/badge/Platform-MediaTek%20Filogic-FF6B35.svg?style=flat-square)](#-一-硬件平台与固件底层概述)
[![Device](https://img.shields.io/badge/Device-Hiveton%20H5000M-blue.svg?style=flat-square)](#-目标设备与编译配置)
[![Modem](https://img.shields.io/badge/Modem-MT5700M%205G-success.svg?style=flat-square)](#1-mt5700m-5g-模组支持-luci-app-mt5700m)
[![Workflow](https://github.com/LianXia233/OpenWRT-CI-H5000M/actions/workflows/WRT-BUILD.yml/badge.svg?style=flat-square)](https://github.com/LianXia233/OpenWRT-CI-H5000M/actions)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg?style=flat-square)](LICENSE)

*全自动化 GitHub Actions 云端构建 · 深度适配 MT5700M 蜂窝模组 · 硬件级风扇温控与网络双链路无缝切换*

---

</div>

## ⚡ 快速开始

本仓库依托 GitHub Actions 实现自动化云端编译，无需本地搭建交叉编译环境。

### 1. 核心工作流一览

| 入口工作流 | 调度方式 | 核心功能与说明 |
| :--- | :--- | :--- |
| **WRT-BUILD** | 手动 `workflow_dispatch` | 手动编译 `MEDIATEK-WIFI-YES`，支持临时传参追加插件或快速验证配置（`TEST=true`） |
| **MTK-AUTO** | 定时联动（`Auto-Clean` 完成后）/ 手动 | 全量自动构建最新主线固件并自动归档发布至 `Releases` |
| **Auto-Clean** | 每日 05:00 (CST) 定时 / 手动 | 定期清理历史构建资产（保留最新 1 份 Release 并清理 30 天前的 Runs 记录） |
| **Cache-Clean** | 每周定时 / 手动 | 释放 GitHub Actions 编译缓存，防止构建缓存膨胀或依赖冲突 |

### 2. 手动编译触发步骤

1. 进入仓库的 **Actions** 标签页。
2. 在左侧工作流列表中选择 **WRT-BUILD**。
3. 点击右侧 **Run workflow** 浮窗，按需填写参数（如测试模式、扩展插件列表）。
4. 编译完成后，固件制品将自动上传至仓库的 **Releases** 页面。

> [!TIP]
> 仓库根目录内置的 [`index.html`](./index.html) 为固件发布展示落地页，可直接启用 **GitHub Pages** 托管，亦可在本地浏览器打开直观浏览设备适配特性与下载链接。

---

## 📂 项目结构

```text
OpenWRT-CI-H5000M/
├── .github/workflows/
│   ├── WRT-CORE.yml          # 云编译底层执行引擎（被 WRT-BUILD / MTK-AUTO 复用）
│   ├── WRT-BUILD.yml         # 手动触发定制编译入口
│   ├── MTK-AUTO.yml          # 每日定时自动构建并发布 Release
│   ├── Auto-Clean.yml        # 历史 Release 与构建日志自动轮换清理
│   └── Cache-Clean.yml       # Actions 依赖缓存定时清理
├── Config/
│   ├── GENERAL.txt           # 全局内核模块、网络协议栈与 H5000M 专属插件清单
│   └── MEDIATEK-WIFI-YES.txt # 针对 Hiveton H5000M 设备的 Target 与 Wi-Fi 驱动配置
├── Scripts/
│   ├── Packages.sh          # 第三方扩展插件源同步与版本拉取
│   ├── Handles.sh           # HomeProxy 等网络组件预置与冲突修复
│   └── Settings.sh          # 系统默认 IP、Wi-Fi SSID/密码、主机名等底层初始化
├── index.html                # 固件发布落地页（支持 GitHub Pages）
├── LICENSE                   # 开源许可协议
└── README.md                 # 固件说明文档

```

---

## 🎯 目标设备与编译配置

本项目专为 **Hiveton H5000M（鼎桥 MT5700M 5G CPE）** 设备打造，配置目标高度收敛：

| 编译配置文件 | 目标平台架构 | 适配设备型号 | Wi-Fi 状态 | 适用场景 |
| --- | --- | --- | --- | --- |
| `MEDIATEK-WIFI-YES` | MediaTek Filogic | Hiveton H5000M | ✅ 启用 | 5G 移动蜂窝路由、无线 AP 与家庭主路由 |

---

## 📡 一、 硬件平台与固件底层概述

**Hiveton H5000M** 是一款面向高吞吐场景的旗舰级 5G CPE 路由器，核心用于将 5G 移动蜂窝网络高速转化为千兆局域网与双频无线覆盖。

| 核心维度 | 架构与实现方案 |
| --- | --- |
| 🏗️ **底层底包** | **基于 ImmortalWrt 主线（VIKINGYFY/immortalwrt @ owrt）源码构建**。内核深度集成硬件加速驱动（`kmod-cryptodev`、`kmod-tls`），全面释放加密隧道与代理分流的数据吞吐潜能。 |
| 🖥️ **计算平台** | 搭载 **联发科 (MediaTek) Filogic** 高性能网络处理器平台，原生支持硬件级 Packet Steering 与 Wi-Fi 6 (802.11ax) 高并发大带宽无线传输。 |
| 📶 **蜂窝模组** | 深度集成 **鼎桥 MT5700M 5G 模组**，支持三大运营商全网通 5G SA/NSA 双模，即插即用无需手动拨号配置。 |
| ❄️ **热设计架构** | 配备**主动可控调速静音散热风扇**，配合全铝散热片快速带走 5G 模组与 CPU 满载热量，保障 7×24 小时高吞吐不降频。 |

---

## 🧩 二、 核心专属 5G CPE 插件

固件深度集成了由 **FAN789** 开发的硬件级适配套件，彻底补全 5G CPE 在路由器系统下的交互短板：

### 1. MT5700M 5G 模组支持 (`luci-app-mt5700m`)

作为 CPE 的网络命脉，该插件为 MT5700M 模组提供了完整的协议栈驱动与 LuCI 可视化控制台：

* 📊 **实时网络拓扑**：动态展示当前蜂窝网络类型（SA / NSA）、信号强度（RSRP / RSRQ / SINR）、服务小区频段（Band）、运营商信息及设备 IMEI / IMSI。
* 🔌 **多协议支持**：支持 QMI、NCM、ECM 等多种通信协议无缝切换，提供极低延迟的数据通道。
* ⚙️ **内置 AT 终端**：基于后台 `ubus-at-daemon`，支持在 Web 界面直接向模组下发 AT 指令，轻松实现频段锁定（Lock Band）、小区锁定及基带固件调试。
* ✉️ **短信中枢服务**：内置 `sms-tool` 引擎，支持在后台直接收发短信，方便接收运营商套餐流量与缴费通知。

### 2. 硬件级智能风扇温控 (`luci-app-h5000m-fancontrol`)

针对 5G 蜂窝模组在高负载上传下载时的剧烈发热，提供精准的闭环散热管理：

* 🌡️ **双传感器轮询**：实时并发采集 SoC 核心与 MT5700M 基带模组的温度数据。
* 🌀 **PWM 阶梯变速**：预设多级触发区间，根据双路最高温度自适应匹配风扇转速百分比，在待机静音与满载散热间达成最佳平衡。
* 🛠️ **策略高度自定义**：支持自主设定起转温度、警戒温度阈值及调速步长，适应不同季节与摆放环境。

### 3. 网络模式无缝切换 (`luci-app-h5000m-netmode`)

为 5G 蜂窝与传统 WAN 口有线光纤双接入场景提供一键化管理：

* 🔄 **模式快速指派**：支持“仅 5G 蜂窝”、“仅有线 WAN”以及“多线并发 / 故障自动转移”三大核心场景快速切换。
* ⚡ **高可用容灾**：与 `mwan3` 状态机联动，毫秒级探测链路健康度，主链路中断时自动倒换备用链路，保障关键业务零断连。

---

## 🛠️ 三、 系统级扩展与服务支持

* **加密加速引擎**：默认集成 `kmod-cryptodev` 与 `kmod-tls`，使 HomeProxy、OpenClash 等科学分流工具在千兆满速下 CPU 占用降低 40% 以上。
* **USB 驱动协议栈**：打包 `kmod-usb-core`、`kmod-usb3`、`kmod-usb-net-qmi-wwan` 及 `kmod-usb-serial`，保障外部拓展模组即插即用。
* **轻量 NAS 与存储扩展**：原生支持 NVMe 固态硬盘（`kmod-nvme`）挂载，结合 BTRFS 文件系统与 Samba4，打造稳定私有云。
* **安全异地组网**：内置 EasyTier、Tailscale、ZeroTier 等主流虚拟局域网方案，随时随地安全直连家中设备。

---

## 💖 鸣谢与致敬

本固件的自动化构建体系、底层调优与硬件模组适配离不开以下优秀的开源项目与开发者：

* 🐧 **[ImmortalWrt](https://github.com/immortalwrt/immortalwrt/?utm_source=gemini)**：提供功能丰富、性能卓越的主线底层路由源码。
* 👤 **[VIKINGYFY](https://github.com/VIKINGYFY?utm_source=gemini)**：为本项目提供经过长期实机验证的云端构建脚手架、底包配置与插件优化模板。
* 👤 **[FAN789](https://github.com/FAN789?utm_source=gemini)**：为 Hiveton H5000M 研发了关键的 [luci-app-mt5700m](https://github.com/FAN789/luci-app-mt5700m?utm_source=gemini)、[luci-app-h5000m-fancontrol](https://github.com/FAN789/luci-app-h5000m-fancontrol?utm_source=gemini) 与 [luci-app-h5000m-netmode](https://github.com/FAN789/luci-app-h5000m-netmode?utm_source=gemini) 驱动插件。

---

> 📅 **维护周期**：持续随 ImmortalWrt 主线（VIKINGYFY/immortalwrt @ owrt）更新
> 📜 **许可协议**：本项目基于 [GPL-3.0](https://www.google.com/search?q=LICENSE&utm_source=gemini) 开源
