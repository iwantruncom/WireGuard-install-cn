# 🚀 WireGuard 一键安装脚本（中文版）

> 本项目基于开源社区经典项目 [angristan/wireguard-install](https://github.com/angristan/wireguard-install) 进行二次开发。  
> 更多 VPN 机场教程请访问：https://iwantrun.com/freevpn

---

## 🌟 新增功能（与原版的区别）

1. 全中文菜单，方便新手部署。
2. 安装完成后自动生成二维码，手机扫码即可连接 VPN。
3. 环境依赖全自动补全，自动识别操作系统。
4. 简单的交互方式，将复杂的网络参数配置提示词，大幅降低部署门槛。

---

## 🖼️ 安装演示

<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/fc64351d-26e7-45a5-8d5e-c9d86eaa6518" 
    alt="WireGuard 中文版安装演示图" 
    width="520"
  />
</p>

<p align="center">
  <sub>安装完成后自动生成二维码，手机扫码即可连接 WireGuard VPN</sub>
</p>

---

## 📖 项目理念

本脚本由 [自由档案馆](https://iwantrun.com/) 汉化与维护。

感谢原作者 [angristan](https://github.com/angristan) 的开源项目。  
感谢 [张狗剩同志](https://x.com/goshenggo) 的催更。

在一个信息被高墙阻隔、真相被选择性遮蔽的时代，工具本身也可以成为一种微小但具体的抵抗。

所谓的“境外势力”，不应成为人们获取信息的恐惧来源；  
所谓的“盛世繁华”，也不应以封锁知识、限制言论为代价。

汉化并修复这个工具，不只是为了让部署 WireGuard 变得更简单，也是为了让更多被困在信息茧房中的人，拥有接触真实世界的可能。

---

## 🔒 安全声明

- 本脚本 **不含任何第三方预编译包**，所有组件均从系统官方软件源拉取。
- 脚本 **不收集、不上传任何数据**，所有配置仅保存在本机。
- 密钥由 WireGuard 官方工具在本地生成，**全程不经过任何第三方**。
- 配置文件权限设置为 `600`，**仅 root 可读**。
- 如需审计代码，请对照 [原始项目](https://github.com/angristan/wireguard-install) 自行核查。

---

## 📋 系统要求

支持以下 Linux 发行版，需 **root 权限**：

| 系统 | 最低版本要求 |
|------|--------------|
| Debian | 10 (Buster) 及以上 |
| Ubuntu | 18.04 及以上 |
| Fedora | 32 及以上 |
| CentOS / AlmaLinux / Rocky | 8 及以上 |
| Oracle Linux | 8 及以上 |
| Arch Linux | 最新版 |
| Alpine Linux | 最新版 |

> ⚠️ **注意**：不支持 OpenVZ 和 LXC 虚拟化环境。

---

## 🚀 一键安装指南

SSH 登录到你的服务器，使用 root 用户执行以下命令：

```bash
wget https://raw.githubusercontent.com/iwantruncom/WireGuard-install-cn/main/wireguard-install-cn.sh
chmod +x wireguard-install-cn.sh
./wireguard-install-cn.sh
```

脚本会弹出安装向导，大部分选项直接按回车键，使用默认值即可。

安装完成后，屏幕上会自动打印二维码，打开手机 WireGuard 客户端扫码即可连接。

---

## 🛠️ 管理客户端（增删设备）

安装完成后，如果你想给电脑、手机或其他设备添加节点，只需重新运行脚本即可进入管理菜单：

```bash
./wireguard-install-cn.sh
```

你会看到类似菜单：

```text
请选择操作：
  1) 添加新客户端
  2) 查看客户端列表
  3) 删除客户端
  4) 卸载 WireGuard
  5) 退出
```

---

## 🚨 【重要】新手必看

如果你安装完成后，显示“已连接”，但完全无法上网：

👉 **99% 是 VPS 服务商防火墙拦截了流量！**

### 解决方案

进入你的云服务器控制台网页，找到 **安全组（Security Group）** 或 **防火墙（Firewall）** 设置：

1. 添加一条 **入站规则（Inbound）**。
2. 协议必须选择：**UDP**  
   > ⚠️ 绝大多数新手选成了 TCP，导致无法上网。
3. 端口填写：你安装时终端显示的端口号，例如 `51413`。
4. 来源 IP 填写：`0.0.0.0/0`，表示允许所有 IP 访问。

---

## 📱 客户端官方下载

| 平台 | 获取方式 |
|------|----------|
| Windows / Linux | 前往官网：https://www.wireguard.com/install/ |
| macOS | App Store 搜索 `WireGuard` |
| iOS 苹果手机 | App Store 需要切换非国区账号，如美区账号，然后搜索 `WireGuard` 下载 |
| Android 安卓手机 | 国内应用市场通常无法下载，请前往官网下载 APK，或在 Google Play 搜索 `WireGuard` |

---

## 📜 协议与鸣谢

本项目遵循 MIT License。

原始项目版权归 [angristan](https://github.com/angristan) 所有。

---

## 🌐 更多教程

获取更多 VPN 翻墙教程与自由资讯，请访问：

[自由档案馆](https://iwantrun.com/)
