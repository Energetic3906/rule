#!/bin/sh
# =========================================================
# Shadowsocks-Rust 智能部署与自动更新脚本 (Alpine优化版)
# =========================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Shadowsocks-Rust 智能部署/更新脚本 ===${NC}"

# 1. 检查并读取旧配置 (实现记忆功能)
CONFIG_FILE="/etc/shadowsocks/config.json"
OLD_PORT=""
OLD_PWD=""
DNS_SERVER="1.1.1.1"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}[*] 检测到已有配置，正在读取旧参数以保持兼容...${NC}"
    # 提取旧端口和密码
    OLD_PORT=$(grep '"server_port":' $CONFIG_FILE | sed -E 's/.*: ([0-9]+),.*/\1/')
    OLD_PWD=$(grep '"password":' $CONFIG_FILE | sed -E 's/.*: "(.+)",.*/\1/')
    DNS_SERVER=$(grep '"nameserver":' $CONFIG_FILE | sed -E 's/.*: "(.+)",.*/\1/')
fi

# 2. 交互式逻辑
if [ -n "$OLD_PORT" ] && [ -n "$OLD_PWD" ]; then
    echo -e "    -> 发现旧配置：端口 $OLD_PORT，密码已锁定，将执行无损升级。"
    server_port=$OLD_PORT
    password=$OLD_PWD
else
    echo "未发现旧配置，开始初始化安装："
    echo "请选择服务器位置（影响 DNS 选优）:"
    echo "1. 国内 (使用 223.5.5.5)"
    echo "2. 国外 (使用 1.1.1.1)"
    
    # 兼容性修改：不用 read -p
    printf "请输入编号 (默认2): "
    read choice
    choice=${choice:-2}
    
    # 安全性修改：使用 case 防止输入非数字报错
    case "$choice" in
        1) DNS_SERVER="223.5.5.5" ;;
        *) DNS_SERVER="1.1.1.1" ;;
    esac

    printf "请输入端口 (默认 3000): "
    read server_port
    server_port=${server_port:-3000}

    echo -e "${GREEN}[*] 正在生成符合 2022 规范的强密钥...${NC}"
    password=$(head -c 32 /dev/urandom | base64 | tr -d '\n')
fi

# 3. 系统依赖安装
if [ -f /etc/alpine-release ]; then
    OS_TYPE="alpine"
    apk add --no-cache curl tar xz ca-certificates >/dev/null 2>&1
else
    OS_TYPE="debian"
    apt-get update -qq && apt-get install -y curl tar xz-utils ca-certificates >/dev/null 2>&1
fi

# 4. 动态获取最新版本并下载
echo -e "${GREEN}[*] 正在检测 Shadowsocks-Rust 最新版本...${NC}"
LATEST_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}[!] 无法获取最新版本，回退至稳定版 v1.23.5${NC}"
    LATEST_TAG="v1.23.5"
fi

cd /tmp
# 判断 libc 类型
[ "$OS_TYPE" = "alpine" ] && LIBC="musl" || LIBC="gnu"
FILE_NAME="shadowsocks-${LATEST_TAG}.x86_64-unknown-linux-${LIBC}.tar.xz"

echo -e "${GREEN}[*] 正在下载并替换二进制文件 ($LATEST_TAG)...${NC}"
curl -sLO "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${LATEST_TAG}/${FILE_NAME}"

# 检查下载是否成功
if [ ! -f "$FILE_NAME" ]; then
    echo -e "${RED}[Error] 下载失败，请检查网络连接。${NC}"
    exit 1
fi

tar -xJf "$FILE_NAME"

# 停止旧服务
if [ "$OS_TYPE" = "alpine" ]; then
    rc-service shadowsocks stop >/dev/null 2>&1
else
    systemctl stop shadowsocks >/dev/null 2>&1
fi

cp ssserver ssservice /usr/local/bin/ && chmod +x /usr/local/bin/sss*

# 5. 写入配置文件
mkdir -p /etc/shadowsocks
cat > $CONFIG_FILE <<EOL
{
    "server": "0.0.0.0",
    "server_port": $server_port,
    "method": "2022-blake3-aes-256-gcm",
    "password": "$password",
    "timeout": 300,
    "nameserver": "$DNS_SERVER",
    "mode": "tcp_and_udp",
    "fast_open": false
}
EOL

# 6. 配置/重启服务
if [ "$OS_TYPE" = "alpine" ]; then
    if [ ! -f "/etc/init.d/shadowsocks" ]; then
        cat > /etc/init.d/shadowsocks <<'EOF'
#!/sbin/openrc-run
command="/usr/local/bin/ssserver"
command_args="-c /etc/shadowsocks/config.json"
command_background="yes"
pidfile="/run/shadowsocks.pid"
EOF
        chmod +x /etc/init.d/shadowsocks
        rc-update add shadowsocks default >/dev/null 2>&1
    fi
    rc-service shadowsocks restart >/dev/null 2>&1
else
    if [ ! -f "/etc/systemd/system/shadowsocks.service" ]; then
        cat > /etc/systemd/system/shadowsocks.service <<EOL
[Unit]
Description=Shadowsocks-Rust
After=network.target
[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/config.json
Restart=always
[Install]
WantedBy=multi-user.target
EOL
        systemctl daemon-reload
        systemctl enable shadowsocks >/dev/null 2>&1
    fi
    systemctl restart shadowsocks
fi

# 7. 结果展示
PUBLIC_IP=$(curl -s -4 ifconfig.me)
echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${GREEN} 🚀 部署/更新成功！${NC}"
echo -e "---------------------------------------------------------------"
echo -e " 状态: $([ -n "$OLD_PORT" ] && echo "版本已更新，配置保持不变" || echo "全新安装完成")"
echo -e " 地址: $PUBLIC_IP"
echo -e " 端口: $server_port"
echo -e " 密码: $password"
echo -e " 算法: 2022-blake3-aes-256-gcm"
echo -e "---------------------------------------------------------------"
echo -e " SS链接:"
echo -e " ss://$(echo -n "2022-blake3-aes-256-gcm:${password}" | base64 | tr -d '\n')@${PUBLIC_IP}:${server_port}#SS-Rust"
echo -e "${GREEN}===============================================================${NC}"

# 清理
rm -rf /tmp/shadowsocks*
# rm "$0" # 注释掉自删除，方便调试