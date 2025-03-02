#!/bin/bash
clear
echo "-------------安装--------------"
echo "请选择操作："
echo "【1】一键安装shadow"
echo "【2】一键安装x-ui(推荐)"
echo "【3】一键安装XrayR(推荐)"
echo "【4】一键安装Xboard 节点管理系统"
echo "【5】一键安装 Alist"
echo "【6】添加nginx"
echo "【7】一键安装MySQL"
echo
echo "-------------日志--------------"
echo "【8】检查shadowsocks-libev服务状态"
echo "【9】查看shadowsocks-libev服务日志"
echo "【10】查看x-ui服务日志"
read -p "请输入选项： " input

if [ "$input" == "1" ]; then
    # 安装shadowsocks-libev的步骤省略
    echo "shadowsocks-libev安装步骤"
elif [ "$input" == "2" ]; then
    echo "一键安装x-ui"
    apt update -y 
    apt install curl wget -y
    bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) 
    clear
    echo "安装成功"
    echo "使用文档：https://v2rayssr.com/reality.html" 
    echo "选择 8  查看面板信息"
    x-ui
elif [ "$input" == "3" ]; then
    echo "一键安装XrayR"
    apt update -y 
    apt install curl wget -y
    bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
    clear

    # 请求用户输入NodeID
    read -p "请输入NodeID: " ID
    echo "节点类型  V2ray, Vmess, Vless, Shadowsocks, Trojan, Shadowsocks-Plugin"
    read -p "请输入节点类型类型: " NoteID

    # 使用用户输入的NodeID替换配置文件中的NodeID
    sudo bash -c "cat <<EOF > /etc/XrayR/config.yml
Log:
  Level: warning # Log level: none, error, warning, info, debug
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/rouating.html for help
InboundConfigPath: # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
  - PanelType: \"NewV2board\" # Panel type: SSpanel, NewV2board, PMpanel, Proxypanel, V2RaySocks, GoV2Panel, BunPanel
    ApiConfig:
    # 需要修改处
      ApiHost: \"******************************************************************************************************/\"
      ApiKey: \"*******************************************************************************************************\"
      NodeID: $ID
      NodeType: $NoteID # Node type: V2ray, Vmess, Vless, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: true  # Enable Vless for V2ray Type
      VlessFlow: \"xtls-rprx-vision\" # Only support vless
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # /etc/XrayR/rulelist Path to local rulelist file
      DisableCustomConfig: false # disable custom config for sspanel
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      AutoSpeedLimitConfig:
        Limit: 0 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 0 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 0 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 0 # How many minutes will the limiting last (unit: minute)
      GlobalDeviceLimitConfig:
        Enable: false # Enable the global device limit of a user
        RedisNetwork: tcp # Redis protocol, tcp or unix
        RedisAddr: 127.0.0.1:6379 # Redis server address, or unix socket path
        RedisUsername: # Redis username
        RedisPassword: YOUR PASSWORD # Redis password
        RedisDB: 0 # Redis DB
        Timeout: 5 # Timeout for redis request
        Expiry: 60 # Expiry time (second)
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        - SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      DisableLocalREALITYConfig: true # disable local reality config
      EnableREALITY: true # Enable REALITY
      REALITYConfigs:
        Show: true # Show REALITY debug
        Dest: www.amazon.com:443 # Required, Same as fallback
        ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
        ServerNames: # Required, list of available serverNames for the client, * wildcard is not supported at the moment.
          - www.amazon.com
        PrivateKey: YOUR_PRIVATE_KEY # Required, execute './XrayR x25519' to generate.
        MinClientVer: # Optional, minimum version of Xray client, format is x.y.z.
        MaxClientVer: # Optional, maximum version of Xray client, format is x.y.z.
        MaxTimeDiff: 0 # Optional, maximum allowed time difference, unit is in milliseconds.
        ShortIds: # Required, list of available shortIds for the client, can be used to differentiate between different clients.
          - \"\"
          - 0123456789abcdef
      CertConfig:
        CertMode: dns # Option about how to get certificate: none, file, http, tls, dns. Choose \"none\" will forcedly disable the tls config.
        CertDomain: \"node1.test.com\" # Domain to cert
        CertFile: /etc/XrayR/cert/node1.test.com.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/cert/node1.test.com.key
        Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
EOF"
    sudo XrayR restart
    echo "XrayR配置完成，NodeID已设置为$ID"
elif [ "$input" == "4" ]; then
    # 检查 Docker 是否已安装
    if command -v docker >/dev/null 2>&1; then
        echo "Docker 已经安装，跳过安装"
    else
        echo "Docker 未安装，开始安装"
        curl -sSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
    fi

    # 确保 git 已安装
    apt install git -y

    # 克隆 Xboard 仓库并安装
    git clone -b docker-compose --depth 1 https://github.com/cedar2025/Xboard
    cd Xboard
    clear

    # 运行 Xboard 安装
    docker compose run -it --rm xboard php artisan xboard:install
    docker compose up -d

    # 获取外网 IP
    IP=$(curl -s ifconfig.me)
    echo "Xboard 节点管理系统安装成功"
    echo "访问 http://$IP:7001"

elif [ "$input" == "5" ]; then
    echo "一键安装 Alist"
    curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install
    echo "Alist 安装完成"
    cd /opt/alist
    read -p "请输入设置的密码： " PASSWORD
    ./alist admin set $PASSWORD
elif [ "$input" == "6" ]; then
    echo "添加nginx"
    apt install nginx -y
    mkdir -p /etc/nginx/cert
    echo "请输入完整的公钥内容，然后输入Ctrl+D保存："
    cat > /etc/nginx/cert/cert.pem

    # 处理多行私钥输入
    echo "请输入完整的私钥内容，然后输入Ctrl+D保存："
    cat > /etc/nginx/cert/key.pem

    read -p "请输入服务 IP 和端口（例如：http://127.0.0.1:8080）：" IP
    read -p "请输入域名地址：" domain
   
    # 删除 nginx.conf 的旧配置，从第 6 行开始删除所有行
    sudo sed -i '6,$d' /etc/nginx/nginx.conf

    # 定义新的 nginx 配置
    nginx_config="events {
        worker_connections 1024;
    }

    http {
        client_max_body_size 1000m;

        server {
            listen 80;
            server_name $domain;
            return 301 https://\$host\$request_uri;
        }
 
        server {
           listen 443 ssl http2;
           server_name $domain;
           ssl_certificate /etc/nginx/cert/cert.pem;
           ssl_certificate_key /etc/nginx/cert/key.pem;

            location / {
                proxy_pass $IP;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection \"Upgrade\";
                proxy_set_header Host \$host;
            }
        }
    }"

    # 使用 printf 保持格式输出到 nginx 配置文件
    printf "%s\n" "$nginx_config" | sudo tee -a /etc/nginx/nginx.conf


    nginx -t
    nginx -s reload
    echo "nginx 安装并配置完成"
elif [ "$input" == "7" ]; then
    echo "一键安装 MySQL"
    apt update -y
    apt install mysql-server -y
    read -p "输入数据库密码：" pwd
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$pwd'; FLUSH PRIVILEGES;"

    read -p "输入创建的数据库:" data
    mysql -u root -p$pwd -e "CREATE DATABASE $data;"
    sudo sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "运行如下开启远程访问： 
CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '$pwd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"
    echo "MySQL 安装完成"
elif [ "$input" == "8" ]; then
    sudo systemctl status shadowsocks-libev
elif [ "$input" == "9" ]; then
    sudo journalctl -u shadowsocks-libev.service -f
elif [ "$input" == "10" ]; then
    x-ui status
else
    echo "无效的选项，程序退出。"
fi
