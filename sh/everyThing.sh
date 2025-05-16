#!/usr/bin/env bash
# fq.sh - Xioaruan 自用工具合集
# 功能：一键安装 x-ui、XrayR、Xboard、Alist、RustDesk 服务端，以及快速配置 Nginx

###############################################################################
# 前置检查
###############################################################################
[[ $EUID -eq 0 ]] || { echo "请以 root 身份运行此脚本！" >&2; exit 1; }

set -e                                  # 任何错误即退出
export DEBIAN_FRONTEND=noninteractive   # apt 静默安装

apt-get update -y
apt-get install -y unzip wget curl

###############################################################################
# 公用函数
###############################################################################
command_exists() { command -v "$1" >/dev/null 2>&1; }

confirm_or_continue() {                 # gum confirm 返回非 0 不结束脚本
    gum confirm "$1" || true
}

###############################################################################
# gum 安装
###############################################################################
install_gum() {
    echo "[gum] 未检测到 gum，开始安装..."
    command_exists wget || apt-get install -y wget
    local arch=$(dpkg --print-architecture)
    case "$arch" in
        amd64|arm64) GUM_ARCH="$arch" ;;
        *) echo "暂不支持架构：$arch，跳过 gum 安装。" >&2; return 1 ;;
    esac
    local version="0.13.0"
    local url="https://github.com/charmbracelet/gum/releases/download/v${version}/gum_${version}_${GUM_ARCH}.deb"
    wget -qO /tmp/gum.deb "$url"
    dpkg -i /tmp/gum.deb || apt-get -f install -y
    rm -f /tmp/gum.deb
}

command_exists gum || install_gum

###############################################################################
# 安装模块
###############################################################################
install_xui() {
    gum style --foreground 212 -- '--- 一键安装 x-ui ---'
    apt-get update -y && apt-get install -y curl wget
    gum spin --title "下载并执行安装脚本..." -- bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
    clear
    gum style --foreground 212 -- "x-ui 安装成功！使用文档：https://v2rayssr.com/reality.html"
    confirm_or_continue "x-ui 安装完成?"
}

install_xrayr() {
    gum style --foreground 212 -- '--- 一键安装 XrayR ---'
    apt-get update -y && apt-get install -y curl wget
    gum spin --title "下载并执行安装脚本..." -- bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
    clear
    local ID=$(gum input --placeholder "请输入 NodeID")
    local Type=$(gum choose "V2ray" "Vmess" "Vless" "Shadowsocks" "Trojan" "Shadowsocks-Plugin" --header "请选择节点类型:")
    local ApiHost=$(gum input --placeholder "请输入 ApiHost (面板地址，例如：https://example.com)")
    local ApiKey=$(gum input --placeholder "请输入 ApiKey (面板通信密钥)" --password)
    gum spin --title "写入配置..." -- bash -c "cat >/etc/XrayR/config.yml <<EOF
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
      ApiHost: \"${ApiHost}\"
      ApiKey: \"${ApiKey}\"
      NodeID: $ID
      NodeType: $Type # Node type: V2ray, Vmess, Vless, Shadowsocks, Trojan, Shadowsocks-Plugin
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
    gum spin --title "重启服务..." -- XrayR restart
    gum style --foreground 212 -- "XrayR 配置完成！"
    confirm_or_continue "XrayR 安装和配置完成?"
}

install_xboard() {
    gum style --foreground 212 -- '--- 一键安装 Xboard 节点管理系统 ---'
    if ! command_exists docker; then
        confirm_or_continue "Docker 未安装，是否现在安装？" || return
        gum spin --title "安装 Docker..." -- bash <(curl -sSL https://get.docker.com)
        systemctl enable --now docker
    fi
    command_exists git || { apt-get update -y && apt-get install -y git; }
    gum spin --title "克隆仓库..." -- git clone -b docker-compose --depth 1 https://github.com/cedar2025/Xboard
    cd Xboard || { gum style --foreground red -- "进入目录失败"; return; }
    gum spin --title "执行安装..." -- docker compose run -it --rm xboard php artisan xboard:install
    gum spin --title "后台启动..." -- docker compose up -d
    local IP=$(curl -s ifconfig.me)
    gum style --foreground 212 -- "Xboard 已安装，访问: http://${IP}:7001"
    cd ..
    confirm_or_continue "Xboard 安装完成?"
}

install_alist() {
    gum style --foreground 212 -- '--- 一键安装 Alist ---'
    gum spin --title "下载安装脚本..." -- bash -c "$(curl -fsSL https://alist.nn.ci/v3.sh)" install
    cd /opt/alist || { gum style --foreground red -- "进入 /opt/alist 失败"; return; }
    local PASS=$(gum input --placeholder "请输入管理员密码" --password)
    gum spin --title "设置管理员密码..." -- ./alist admin set "$PASS"
    gum style --foreground 212 -- "Alist 安装完成！目录: /opt/alist"
    cd - >/dev/null
    confirm_or_continue "Alist 安装完成?"
}

install_rustdesk() {
    gum style --foreground 212 -- '--- 一键安装 RustDesk 服务端 (i386) ---'
    VERSION="1.1.14"; ARCH="i386"
    ZIP_NAME="rustdesk-server-linux-${ARCH}.zip"
    URL="https://github.com/rustdesk/rustdesk-server/releases/download/${VERSION}/${ZIP_NAME}"
    gum spin --title "下载 RustDesk..." -- wget -qO "${ZIP_NAME}" "${URL}"
    mkdir -p rustdesk && mv "${ZIP_NAME}" rustdesk/rustdesk.zip
    pushd rustdesk >/dev/null
    gum spin --title "解压..." -- unzip -q rustdesk.zip
    chmod -R 755 i386
    gum style --foreground 212 -- "RustDesk 已解压于 $(pwd)/i386"
    popd >/dev/null
    confirm_or_continue "RustDesk 安装完成?"
}

add_nginx() {
    gum style --foreground 212 -- '--- 添加并配置 Nginx ---'
    command_exists nginx || { apt-get update -y && apt-get install -y nginx; }
    mkdir -p /etc/nginx/cert
    gum style --foreground yellow -- "粘贴公钥 (Ctrl+D 保存):"
    gum write --placeholder "粘贴公钥内容..." | tee /etc/nginx/cert/cert.pem >/dev/null
    gum style --foreground yellow -- "粘贴私钥 (Ctrl+D 保存):"
    gum write --placeholder "粘贴私钥内容..." | tee /etc/nginx/cert/key.pem  >/dev/null
    local IP_PORT=$(gum input --placeholder "后端地址:端口 (如 http://127.0.0.1:8080)")
    local domain=$(gum input --placeholder "请输入域名 (如 example.com)")
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak_$(date +%F_%T)
cat > /etc/nginx/nginx.conf <<EOF
user  www-data;
worker_processes  auto;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    gzip on; gzip_vary on; gzip_comp_level 6;
    client_max_body_size 1000m;
    server { listen 80; server_name ${domain}; return 301 https://\$host\$request_uri; }
    server {
        listen 443 ssl http2;
        server_name ${domain};
        ssl_certificate /etc/nginx/cert/cert.pem;
        ssl_certificate_key /etc/nginx/cert/key.pem;
        location / {
            proxy_pass ${IP_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_buffering off;
        }
    }
}
EOF
    gum spin --title "测试配置..." -- nginx -t
    gum spin --title "重载服务..." -- systemctl reload nginx
    gum style --foreground 212 -- "Nginx 配置完成！"
    confirm_or_continue "Nginx 配置完成?"
}

###############################################################################
# 主菜单
###############################################################################
main_menu() {
    clear
    gum style --border normal --margin "1 2" --padding "1 1" --border-foreground 212 -- '自用工具 (fq.sh - Xioaruan)'
    echo
    gum style --foreground magenta -- "请选择一个操作:"
    echo
    local choice
    choice=$(gum choose \
        "一键安装 x-ui (推荐)" \
        "一键安装 XrayR (推荐)" \
        "一键安装 Xboard 节点管理系统" \
        "一键安装 Alist" \
        "一键安装 RustDesk 服务端" \
        "添加并配置 Nginx" \
        "退出")
    case "$choice" in
        "一键安装 x-ui (推荐)")                install_xui ;;
        "一键安装 XrayR (推荐)")              install_xrayr ;;
        "一键安装 Xboard 节点管理系统")       install_xboard ;;
        "一键安装 Alist")                    install_alist ;;
        "一键安装 RustDesk 服务端")          install_rustdesk ;;
        "添加并配置 Nginx")                  add_nginx ;;
        "退出")                              gum style --foreground green -- "脚本退出。"; exit 0 ;;
    esac
    confirm_or_continue "返回主菜单?" && main_menu
}

main_menu
