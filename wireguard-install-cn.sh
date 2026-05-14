#!/bin/bash

# WireGuard 一键安装脚本（中文精简版）
# 汉化：张狗剩（https://x.com/goshenggo）& 自由档案馆（https://iwantrun.com/）
# 原项目：https://github.com/angristan/wireguard-install

RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "请以 root 身份运行此脚本"
		exit 1
	fi
}

function checkVirt() {
	if command -v virt-what &>/dev/null; then
		VIRT=$(virt-what)
	else
		VIRT=$(systemd-detect-virt)
	fi
	if [[ ${VIRT} == "openvz" ]]; then
		echo "不支持 OpenVZ 虚拟化环境"
		exit 1
	fi
	if [[ ${VIRT} == "lxc" ]]; then
		echo "不支持 LXC 容器环境"
		exit 1
	fi
}

function checkOS() {
	source /etc/os-release
	OS="${ID}"
	if [[ ${OS} == "debian" || ${OS} == "raspbian" ]]; then
		if [[ ${VERSION_ID} -lt 10 ]]; then
			echo "Debian 版本过低，请使用 Debian 10 或更高版本"
			exit 1
		fi
		OS=debian
	elif [[ ${OS} == "ubuntu" ]]; then
		RELEASE_YEAR=$(echo "${VERSION_ID}" | cut -d'.' -f1)
		if [[ ${RELEASE_YEAR} -lt 18 ]]; then
			echo "Ubuntu 版本过低，请使用 Ubuntu 18.04 或更高版本"
			exit 1
		fi
	elif [[ ${OS} == "fedora" ]]; then
		if [[ ${VERSION_ID} -lt 32 ]]; then
			echo "Fedora 版本过低，请使用 Fedora 32 或更高版本"
			exit 1
		fi
	elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
		if [[ ${VERSION_ID} == 7* ]]; then
			echo "CentOS 版本过低，请使用 CentOS 8 或更高版本"
			exit 1
		fi
	elif [[ -e /etc/oracle-release ]]; then
		source /etc/os-release
		OS=oracle
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	elif [[ -e /etc/alpine-release ]]; then
		OS=alpine
	else
		echo "不支持当前系统，支持：Debian、Ubuntu、Fedora、CentOS、AlmaLinux、Oracle、Arch"
		exit 1
	fi
}

function getHomeDirForClient() {
	local CLIENT_NAME=$1
	if [ -z "${CLIENT_NAME}" ]; then
		echo "错误：需要提供客户端名称"
		exit 1
	fi
	if [ -e "/home/${CLIENT_NAME}" ]; then
		HOME_DIR="/home/${CLIENT_NAME}"
	elif [ "${SUDO_USER}" ]; then
		if [ "${SUDO_USER}" == "root" ]; then
			HOME_DIR="/root"
		else
			HOME_DIR="/home/${SUDO_USER}"
		fi
	else
		HOME_DIR="/root"
	fi
	echo "$HOME_DIR"
}

function initialCheck() {
	isRoot
	checkOS
	checkVirt
}

function showQRCode() {
	local CONF_FILE=$1
	local PYTHON_CMD="python3"

	# 检查 python 命令 (Arch Linux 等可能直接叫 python)
	if ! command -v ${PYTHON_CMD} &>/dev/null; then
		if command -v python &>/dev/null; then
			PYTHON_CMD="python"
		else
			echo -e "  ${RED}无法生成二维码：未找到 Python 环境${NC}"
			echo -e "  请将配置文件下载到电脑后手动导入 WireGuard 客户端"
			return 1
		fi
	fi

	# 尝试安装 qrcode 库 (静默执行，适配较新系统的 PEP 668 保护机制)
	if ! ${PYTHON_CMD} -c "import qrcode" 2>/dev/null; then
		${PYTHON_CMD} -m pip install qrcode --quiet --break-system-packages 2>/dev/null || \
		${PYTHON_CMD} -m pip install qrcode --quiet 2>/dev/null
	fi

	# 渲染二维码
	if ${PYTHON_CMD} -c "import qrcode" 2>/dev/null; then
		${PYTHON_CMD} - "${CONF_FILE}" << 'PYSCRIPT'
import sys, qrcode
with open(sys.argv[1]) as f:
    data = f.read().strip()
qr = qrcode.QRCode(border=1)
qr.add_data(data)
qr.make(fit=True)
matrix = qr.get_matrix()
print()
for y in range(0, len(matrix), 2):
    row = ""
    for x in range(len(matrix[y])):
        top = matrix[y][x]
        bot = matrix[y+1][x] if y+1 < len(matrix) else False
        if top and bot:   row += "\033[7m \033[0m"
        elif top:         row += "\033[7m\u2584\033[0m"
        elif bot:         row += "\u2584"
        else:             row += " "
    print(row)
print()
PYSCRIPT
		return 0
	else
		echo -e "  ${RED}无法生成二维码：qrcode 库安装失败${NC}"
		echo -e "  请将配置文件下载到电脑后手动导入 WireGuard 客户端"
		return 1
	fi
}

function installQuestions() {
	echo ""
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "${GREEN}     WireGuard 一键安装脚本（中文版）${NC}"
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "  汉化：张狗剩 & 自由档案馆"
	echo -e "  原项目：https://github.com/angristan/wireguard-install"
	echo ""
	echo -e "${ORANGE}【安全声明】${NC}"
	echo -e "  · 所有组件均从系统官方软件源拉取，不含第三方包"
	echo -e "  · 不收集、不上传任何数据，配置仅保存在本机"
	echo -e "  · 密钥由 WireGuard 官方工具本地生成"
	echo -e "  · 配置文件权限 600，仅 root 可读"
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo ""
	echo "请确认以下参数（直接回车使用默认值）："
	echo ""

	SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
	read -rp "服务器公网 IP 地址（请查看VPS的IP地址）：" -e -i "${SERVER_PUB_IP}" SERVER_PUB_IP

	SERVER_NIC="$(ip -4 route ls | grep default | awk '/dev/ {for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1)}' | head -1)"
	until [[ ${SERVER_PUB_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
		read -rp "公网网卡名称（默认即可）：" -e -i "${SERVER_NIC}" SERVER_PUB_NIC
	done

	until [[ ${SERVER_WG_NIC} =~ ^[a-zA-Z0-9_]+$ && ${#SERVER_WG_NIC} -lt 16 ]]; do
		read -rp "WireGuard 接口名称（默认即可）：" -e -i wg0 SERVER_WG_NIC
	done

	until [[ ${SERVER_WG_IPV4} =~ ^([0-9]{1,3}\.){3} ]]; do
		read -rp "服务端内网 IP（VPN 网段，默认即可）：" -e -i 10.66.66.1 SERVER_WG_IPV4
	done

	RANDOM_PORT=$(shuf -i49152-65535 -n1)
	until [[ ${SERVER_PORT} =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
		read -rp "WireGuard 监听端口（随机或者默认即可） [1-65535]：" -e -i "${RANDOM_PORT}" SERVER_PORT
	done

	until [[ ${CLIENT_DNS_1} =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
		read -rp "首选 DNS（默认即可）：" -e -i 1.1.1.1 CLIENT_DNS_1
	done
	until [[ ${CLIENT_DNS_2} =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
		read -rp "备用 DNS（默认即可）：" -e -i 8.8.8.8 CLIENT_DNS_2
	done

	echo ""
	echo "参数确认完毕，即将开始安装。"
	read -n1 -r -p "按任意键继续..."
	echo ""
}

function installWireGuard() {
	installQuestions

	echo -e "${ORANGE}正在安装 WireGuard 及依赖环境...${NC}"

	if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' && ${VERSION_ID} -gt 10 ]]; then
		apt-get update
		apt-get install -y wireguard iptables resolvconf python3 python3-pip
	elif [[ ${OS} == 'debian' ]]; then
		if ! grep -rqs "^deb .* buster-backports" /etc/apt/; then
			echo "deb http://deb.debian.org/debian buster-backports main" >/etc/apt/sources.list.d/backports.list
			apt-get update
		fi
		apt-get update
		apt-get install -y iptables resolvconf python3 python3-pip
		apt-get install -y -t buster-backports wireguard
	elif [[ ${OS} == 'fedora' ]]; then
		if [[ ${VERSION_ID} -lt 32 ]]; then
			dnf install -y dnf-plugins-core
			dnf copr enable -y jdoss/wireguard
			dnf install -y wireguard-dkms
		fi
		dnf install -y wireguard-tools iptables python3 python3-pip
	elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
		if [[ ${VERSION_ID} == 8* ]]; then
			yum install -y epel-release elrepo-release
			yum install -y kmod-wireguard
		fi
		yum install -y wireguard-tools iptables python3 python3-pip
	elif [[ ${OS} == 'oracle' ]]; then
		dnf install -y oraclelinux-developer-release-el8
		dnf config-manager --disable -y ol8_developer
		dnf config-manager --enable -y ol8_developer_UEKR6
		dnf config-manager --save -y --setopt=ol8_developer_UEKR6.includepkgs='wireguard-tools*'
		dnf install -y wireguard-tools iptables python3 python3-pip
	elif [[ ${OS} == 'arch' ]]; then
		pacman -S --needed --noconfirm wireguard-tools python python-pip
	elif [[ ${OS} == 'alpine' ]]; then
		apk update
		apk add wireguard-tools iptables python3 py3-pip
	fi

	if ! command -v wg &>/dev/null; then
		echo -e "${RED}WireGuard 安装失败，请检查上方输出。${NC}"
		exit 1
	fi

	mkdir /etc/wireguard >/dev/null 2>&1
	chmod 600 -R /etc/wireguard/

	SERVER_PRIV_KEY=$(wg genkey)
	SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)

	echo "SERVER_PUB_IP=${SERVER_PUB_IP}
SERVER_PUB_NIC=${SERVER_PUB_NIC}
SERVER_WG_NIC=${SERVER_WG_NIC}
SERVER_WG_IPV4=${SERVER_WG_IPV4}
SERVER_PORT=${SERVER_PORT}
SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
SERVER_PUB_KEY=${SERVER_PUB_KEY}
CLIENT_DNS_1=${CLIENT_DNS_1}
CLIENT_DNS_2=${CLIENT_DNS_2}
ALLOWED_IPS=0.0.0.0/0" >/etc/wireguard/params

	echo "[Interface]
Address = ${SERVER_WG_IPV4}/24
ListenPort = ${SERVER_PORT}
PrivateKey = ${SERVER_PRIV_KEY}" >"/etc/wireguard/${SERVER_WG_NIC}.conf"

	if pgrep firewalld; then
		FIREWALLD_IPV4_ADDRESS=$(echo "${SERVER_WG_IPV4}" | cut -d"." -f1-3)".0"
		echo "PostUp = firewall-cmd --zone=public --add-interface=${SERVER_WG_NIC} && firewall-cmd --add-port ${SERVER_PORT}/udp && firewall-cmd --add-rich-rule='rule family=ipv4 source address=${FIREWALLD_IPV4_ADDRESS}/24 masquerade'
PostDown = firewall-cmd --zone=public --remove-interface=${SERVER_WG_NIC} && firewall-cmd --remove-port ${SERVER_PORT}/udp && firewall-cmd --remove-rich-rule='rule family=ipv4 source address=${FIREWALLD_IPV4_ADDRESS}/24 masquerade'" >>"/etc/wireguard/${SERVER_WG_NIC}.conf"
	else
		echo "PostUp = iptables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_WG_NIC} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_WG_NIC} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE" >>"/etc/wireguard/${SERVER_WG_NIC}.conf"
	fi

	echo "net.ipv4.ip_forward = 1" >/etc/sysctl.d/wg.conf

	if [[ ${OS} == 'alpine' ]]; then
		sysctl -p /etc/sysctl.d/wg.conf
		rc-update add sysctl
		ln -s /etc/init.d/wg-quick "/etc/init.d/wg-quick.${SERVER_WG_NIC}"
		rc-service "wg-quick.${SERVER_WG_NIC}" start
		rc-update add "wg-quick.${SERVER_WG_NIC}"
	else
		sysctl --system
		systemctl start "wg-quick@${SERVER_WG_NIC}"
		systemctl enable "wg-quick@${SERVER_WG_NIC}"
	fi

	newClient

	echo ""
	echo -e "${GREEN}如需添加更多客户端，重新运行此脚本即可。${NC}"
	echo ""

	if [[ ${OS} == 'alpine' ]]; then
		rc-service --quiet "wg-quick.${SERVER_WG_NIC}" status
	else
		systemctl is-active --quiet "wg-quick@${SERVER_WG_NIC}"
	fi
	WG_RUNNING=$?

	if [[ ${WG_RUNNING} -ne 0 ]]; then
		echo -e "${RED}警告：WireGuard 未能正常启动。${NC}"
		echo -e "${ORANGE}请执行：systemctl status wg-quick@${SERVER_WG_NIC}${NC}"
		echo -e "${ORANGE}若提示找不到设备，重启服务器后重试。${NC}"
	else
		echo -e "${GREEN}WireGuard 已成功启动！${NC}"
		echo -e "${ORANGE}若客户端无法上网，请重启服务器后再试。${NC}"
	fi
}

function newClient() {
	if [[ ${SERVER_PUB_IP} =~ .*:.* ]]; then
		if [[ ${SERVER_PUB_IP} != *"["* ]] || [[ ${SERVER_PUB_IP} != *"]"* ]]; then
			SERVER_PUB_IP="[${SERVER_PUB_IP}]"
		fi
	fi
	ENDPOINT="${SERVER_PUB_IP}:${SERVER_PORT}"

	echo ""
	
	CLIENT_EXISTS=1
	until [[ ${CLIENT_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${CLIENT_EXISTS} == '0' && ${#CLIENT_NAME} -lt 16 ]]; do
		read -rp "客户端名称（随便起个英文名）：" -e CLIENT_NAME
		CLIENT_EXISTS=$(grep -c -E "^### Client ${CLIENT_NAME}\$" "/etc/wireguard/${SERVER_WG_NIC}.conf")
		if [[ ${CLIENT_EXISTS} != 0 ]]; then
			echo -e "${ORANGE}该名称已存在，请换一个。${NC}"
		fi
	done

	for DOT_IP in {2..254}; do
		DOT_EXISTS=$(grep -c "${SERVER_WG_IPV4::-1}${DOT_IP}" "/etc/wireguard/${SERVER_WG_NIC}.conf")
		if [[ ${DOT_EXISTS} == '0' ]]; then
			break
		fi
	done

	if [[ ${DOT_EXISTS} == '1' ]]; then
		echo "子网已满（最多 253 个客户端）"
		exit 1
	fi

	BASE_IP=$(echo "$SERVER_WG_IPV4" | awk -F '.' '{ print $1"."$2"."$3 }')
	IPV4_EXISTS=1
	until [[ ${IPV4_EXISTS} == '0' ]]; do
		read -rp "客户端内网 IP（默认即可）：${BASE_IP}." -e -i "${DOT_IP}" DOT_IP
		CLIENT_WG_IPV4="${BASE_IP}.${DOT_IP}"
		IPV4_EXISTS=$(grep -c "$CLIENT_WG_IPV4/32" "/etc/wireguard/${SERVER_WG_NIC}.conf")
		if [[ ${IPV4_EXISTS} != 0 ]]; then
			echo -e "${ORANGE}该 IP 已被使用，请换一个。${NC}"
		fi
	done

	CLIENT_PRIV_KEY=$(wg genkey)
	CLIENT_PUB_KEY=$(echo "${CLIENT_PRIV_KEY}" | wg pubkey)
	CLIENT_PRE_SHARED_KEY=$(wg genpsk)

	HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
	CLIENT_CONF="${HOME_DIR}/${SERVER_WG_NIC}-client-${CLIENT_NAME}.conf"

	echo "[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${CLIENT_WG_IPV4}/32
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
Endpoint = ${ENDPOINT}
AllowedIPs = 0.0.0.0/0" >"${CLIENT_CONF}"

	echo -e "\n### Client ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CLIENT_WG_IPV4}/32" >>"/etc/wireguard/${SERVER_WG_NIC}.conf"

	wg syncconf "${SERVER_WG_NIC}" <(wg-quick strip "${SERVER_WG_NIC}")

	echo ""
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "${GREEN}  ✅ 客户端「${CLIENT_NAME}」已创建${NC}"
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo ""
	
	# 高亮大字体显示服务器信息
	echo -e "  \033[1;37;44m 服务器：${SERVER_PUB_IP}   端口：${SERVER_PORT}   客户端IP：${CLIENT_WG_IPV4} \033[0m"
	echo ""
	
	# 官方下载链接
	echo -e "  WireGuard客户端官方下载（Windows/macOS/Android/Linux）：https://www.wireguard.com/install/"
	echo ""

	echo -e "${ORANGE}📱 手机连接${NC}（App Store / Google Play 搜索 WireGuard，扫码导入）"
	showQRCode "${CLIENT_CONF}"
	echo ""

	echo -e "${ORANGE}💻 电脑连接${NC}（下载配置文件后用 WireGuard 客户端导入）"
	echo -e "  配置文件：${GREEN}${CLIENT_CONF}${NC}"
	echo ""
	echo -e "  Mac 终端执行："
	echo -e "  ${GREEN}scp root@${SERVER_PUB_IP}:${CLIENT_CONF} ~/Downloads/${NC}"
	echo ""
	echo -e "  Windows 下载："
	echo -e "  · WinSCP（推荐新手）：https://winscp.net  登录后找到上方路径拖出即可"
	echo -e "  · PowerShell：scp root@${SERVER_PUB_IP}:${CLIENT_CONF} %USERPROFILE%\Downloads\ "
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

function listClients() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "/etc/wireguard/${SERVER_WG_NIC}.conf")
	if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
		echo "当前没有任何客户端。"
		exit 1
	fi
	echo ""
	echo "当前客户端列表："
	grep -E "^### Client" "/etc/wireguard/${SERVER_WG_NIC}.conf" | cut -d ' ' -f 3 | nl -s ') '
}

function revokeClient() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "/etc/wireguard/${SERVER_WG_NIC}.conf")
	if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
		echo "当前没有任何客户端。"
		exit 1
	fi

	echo ""
	echo "请选择要删除的客户端："
	grep -E "^### Client" "/etc/wireguard/${SERVER_WG_NIC}.conf" | cut -d ' ' -f 3 | nl -s ') '
	until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
		if [[ ${NUMBER_OF_CLIENTS} == '1' ]]; then
			read -rp "请输入编号 [1]：" CLIENT_NUMBER
		else
			read -rp "请输入编号 [1-${NUMBER_OF_CLIENTS}]：" CLIENT_NUMBER
		fi
	done

	CLIENT_NAME=$(grep -E "^### Client" "/etc/wireguard/${SERVER_WG_NIC}.conf" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
	sed -i "/^### Client ${CLIENT_NAME}\$/,/^$/d" "/etc/wireguard/${SERVER_WG_NIC}.conf"

	HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
	rm -f "${HOME_DIR}/${SERVER_WG_NIC}-client-${CLIENT_NAME}.conf"

	wg syncconf "${SERVER_WG_NIC}" <(wg-quick strip "${SERVER_WG_NIC}")
	echo -e "${GREEN}客户端「${CLIENT_NAME}」已删除。${NC}"
}

function uninstallWg() {
	echo ""
	echo -e "${RED}警告：此操作将卸载 WireGuard 并删除所有配置！${NC}"
	echo -e "${ORANGE}如需保留配置，请先备份 /etc/wireguard 目录。${NC}"
	echo ""
	read -rp "确认卸载？[y/n]：" -e REMOVE
	REMOVE=${REMOVE:-n}
	if [[ $REMOVE == 'y' ]]; then
		checkOS

		if [[ ${OS} == 'alpine' ]]; then
			rc-service "wg-quick.${SERVER_WG_NIC}" stop
			rc-update del "wg-quick.${SERVER_WG_NIC}"
			unlink "/etc/init.d/wg-quick.${SERVER_WG_NIC}"
			rc-update del sysctl
		else
			systemctl stop "wg-quick@${SERVER_WG_NIC}"
			systemctl disable "wg-quick@${SERVER_WG_NIC}"
		fi

		if [[ ${OS} == 'ubuntu' ]] || [[ ${OS} == 'debian' ]]; then
			apt-get remove -y wireguard wireguard-tools
		elif [[ ${OS} == 'fedora' ]]; then
			dnf remove -y --noautoremove wireguard-tools
			if [[ ${VERSION_ID} -lt 32 ]]; then
				dnf remove -y --noautoremove wireguard-dkms
				dnf copr disable -y jdoss/wireguard
			fi
		elif [[ ${OS} == 'centos' ]] || [[ ${OS} == 'almalinux' ]] || [[ ${OS} == 'rocky' ]]; then
			yum remove -y --noautoremove wireguard-tools
			if [[ ${VERSION_ID} == 8* ]]; then
				yum remove --noautoremove kmod-wireguard
			fi
		elif [[ ${OS} == 'oracle' ]]; then
			yum remove --noautoremove wireguard-tools
		elif [[ ${OS} == 'arch' ]]; then
			pacman -Rs --noconfirm wireguard-tools
		elif [[ ${OS} == 'alpine' ]]; then
			apk del wireguard-tools
		fi

		rm -rf /etc/wireguard
		rm -f /etc/sysctl.d/wg.conf

		if [[ ${OS} != 'alpine' ]]; then
			sysctl --system
		fi

		echo -e "${GREEN}WireGuard 已成功卸载。${NC}"
		exit 0
	else
		echo "已取消。"
	fi
}

function manageMenu() {
	echo ""
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "${GREEN}        WireGuard 管理菜单${NC}"
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "  汉化：张狗剩 & 自由档案馆"
	echo -e "  原项目：https://github.com/angristan/wireguard-install"
	echo ""
	echo -e "${ORANGE}【安全声明】${NC}"
	echo -e "  · 所有组件均从系统官方软件源拉取，不含第三方包"
	echo -e "  · 不收集、不上传任何数据，配置仅保存在本机"
	echo -e "  · 密钥由 WireGuard 官方工具本地生成"
	echo -e "  · 配置文件权限 600，仅 root 可读"
	echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo ""
	echo "请选择操作："
	echo "  1) 添加新客户端"
	echo "  2) 查看客户端列表"
	echo "  3) 删除客户端"
	echo "  4) 卸载 WireGuard"
	echo "  5) 退出"
	echo ""
	until [[ ${MENU_OPTION} =~ ^[1-5]$ ]]; do
		read -rp "请输入选项 [1-5]：" MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1) newClient ;;
	2) listClients ;;
	3) revokeClient ;;
	4) uninstallWg ;;
	5) exit 0 ;;
	esac
}

initialCheck

if [[ -e /etc/wireguard/params ]]; then
	source /etc/wireguard/params
	manageMenu
else
	installWireGuard
fi