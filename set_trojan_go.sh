#!/bin/bash

# 第一步：下载和解压 Trojan-Go
cd /root && mkdir trojan && cd trojan && wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip && apt install unzip -y && unzip trojan-go-linux-amd64.zip
# 设置端口
read -p "请输入 trojan_go 端口: " server_port
# 输入“trojan_go 密码：”
read -p "请输入 trojan_go 密码: " password
# 第二步：创建配置文件
read -p "请输入域名: " remote_addr
cat > /root/trojan/config.json << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $server_port,
    "remote_addr": "$remote_addr",
    "remote_port": 80,
    "password": [
        "$password"
    ],
    "ssl": {
        "cert": "/root/trojan/fullchain1.pem",
        "key": "/root/trojan/privkey1.pem",
        "fallback_port": 9443
    }
}
EOF

# 第三步：软链接证书文件到目标目录
sudo ln -s /root/.acme.sh/${remote_addr}_ecc/${remote_addr}.key /root/trojan/
sudo ln -s /root/.acme.sh/${remote_addr}_ecc/fullchain.cer /root/trojan/
# 第四步：创建服务文件
cat > /etc/systemd/system/trojan-go.service << EOF
[Unit]
Description=Trojan-Go Service
After=network.target

[Service]
ExecStart=/root/trojan/trojan-go -config /root/trojan/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 设置文件权限
sudo chmod 644 /etc/systemd/system/trojan-go.service
sudo chmod +x /root/trojan/trojan-go
sudo chmod 644 /root/trojan/${remote_addr}.key
sudo chmod 644 /root/trojan/fullchain.cer

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable trojan-go.service
