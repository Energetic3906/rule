#!/bin/bash

# 第一步：选择服务器处于国外还是国内，要一个判断，1为国外，2为国内；
echo "请选择服务器处于国外还是国内："
echo "1. 国内"
echo "2. 国外"
read -p "请输入选择的编号: " choice

# 第二步：输入“ss-rust 密码：”
read -p "请输入 ss-rust 密码: " password

# 设置端口
read -p "请输入 ss-rust 端口: " server_port

# 第三步：创建目录并编辑配置文件
mkdir -p /root/ss-rust/config

# 第四步：根据选择的服务器类型写入配置文件内容
if [ $choice -eq 1 ]; then
  cat > /root/ss-rust/config/config.json <<EOL
{
    "servers": [
        {
            "server":"0.0.0.0",
            "server_port":$server_port,
            "method":"aes-256-gcm",
            "password":"$password",
            "timeout":300,
            "nameserver":"223.5.5.5",
            "mode":"tcp_and_udp",
            "fast_open": false
        }
    ]
}
EOL
else
  cat > /root/ss-rust/config/config.json <<EOL
{
    "servers": [
        {
            "server":"0.0.0.0",
            "server_port":$server_port,
            "method":"aes-256-gcm",
            "password":"$password",
            "timeout":300,
            "nameserver":"8.8.8.8",
            "mode":"tcp_and_udp",
            "fast_open": false
        }
    ]
}
EOL
fi

# 第五步：编辑docker-compose.yml文件
cd /root/ss-rust

# 第六步：写入docker-compose.yml的内容
cat > /root/ss-rust/docker-compose.yml <<EOL
services:
  shadowsocks:
    image: teddysun/shadowsocks-rust:latest
    container_name: ss-rust
    restart: always
    network_mode: bridge
    ports:
      - "$server_port:$server_port"
      - "$server_port:$server_port/udp"
    volumes:
      - ./config:/etc/shadowsocks-rust
EOL

# 第七步：执行docker-compose命令
cd && cd /root/ss-rust
docker compose pull
docker compose up -d

echo "脚本执行完成！"

# 删除脚本文件
rm $0
