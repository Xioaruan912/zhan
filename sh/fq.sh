#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install gum on Ubuntu/Debian
install_gum() {
    echo "gum 未安装，正在尝试安装..."
    if command_exists apt; then
        local arch
        arch=$(dpkg --print-architecture)
        if [[ "$arch" == "amd64" ]]; then
            GUM_ARCH="amd64"
        elif [[ "$arch" == "arm64" ]]; then
            GUM_ARCH="arm64"
        else
            echo "不支持的系统架构: $arch 用于自动安装 gum。"
            echo "请访问 https://github.com/charmbracelet/gum#installation 手动安装 gum。"
            return 1
        fi
        
        echo "正在从 GitHub 下载 gum_${GUM_ARCH}.deb..."
        local GUM_VERSION="0.13.0" # Example version, update as needed
        local GUM_DEB_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${GUM_ARCH}.deb"

        if curl -sSL "$GUM_DEB_URL" -o "/tmp/gum.deb"; then
            echo "下载完成。正在安装 gum..."
            if sudo dpkg -i /tmp/gum.deb; then
                sudo apt-get install -f -y # Install dependencies if any
                echo "gum 安装成功。"
                rm /tmp/gum.deb
            else
                echo "gum 安装失败 (dpkg -i)。"
                rm /tmp/gum.deb
                echo "请访问 https://github.com/charmbracelet/gum#installation 手动安装 gum。"
                return 1
            fi
        else
            echo "gum 下载失败。"
            echo "请访问 https://github.com/charmbracelet/gum#installation 手动安装 gum。"
            return 1
        fi
    else
        echo "未找到 apt 包管理器。请访问 https://github.com/charmbracelet/gum#installation 手动安装 gum。"
        return 1
    fi
}

# Check if gum is installed, if not, try to install it
if ! command_exists gum; then
    install_gum || exit 1 # Exit if gum installation fails
fi

# --- Option Functions ---

install_xui() {
    gum style --foreground 212 "--- 一键安装 x-ui ---"
    sudo apt update -y 
    sudo apt install curl wget -y 
    gum spin --title "正在下载并执行 x-ui 安装脚本..." -- bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
    clear
    gum style --foreground 212 "x-ui 安装成功！"
    echo "使用文档：https://v2rayssr.com/reality.html"
    echo "请稍后在 x-ui 面板中选择 '8' 查看面板信息。"
    gum confirm "x-ui 安装完成?" 
}

install_xrayr() {
    gum style --foreground 212 "--- 一键安装 XrayR ---"
    sudo apt update -y 
    sudo apt install curl wget -y 
    gum spin --title "正在下载并执行 XrayR 安装脚本..." -- bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
    clear

    local ID
    ID=$(gum input --placeholder "请输入 NodeID")
    local NoteID
    NoteID=$(gum choose "V2ray" "Vmess" "Vless" "Shadowsocks" "Trojan" "Shadowsocks-Plugin" --header "请选择节点类型:")
    local ApiHost
    ApiHost=$(gum input --placeholder "请输入 ApiHost (面板地址，例如：https://example.com)")
    local ApiKey
    ApiKey=$(gum input --placeholder "请输入 ApiKey (面板通信密钥)" --password)

    gum spin --title "正在配置 XrayR..." -- sudo bash -c "cat <<EOF > /etc/XrayR/config.yml
Log:
  Level: warning 
  AccessPath: 
  ErrorPath: 
Nodes:
  - PanelType: \"NewV2board\" 
    ApiConfig:
      ApiHost: \"${ApiHost}\"
      ApiKey: \"${ApiKey}\"
      NodeID: ${ID}
      NodeType: ${NoteID} 
      Timeout: 30 
      EnableVless: false 
      VlessFlow: 
      SpeedLimit: 0 
      DeviceLimit: 0 
      DisableCustomConfig: false 
    ControllerConfig:
      ListenIP: 0.0.0.0 
      UpdatePeriodic: 60 
EOF"

    gum spin --title "正在重启 XrayR 服务..." -- sudo XrayR restart
    gum style --foreground 212 "XrayR 配置完成！"
    echo "NodeID 已设置为: $ID"
    echo "ApiHost 已设置为: $ApiHost"
    echo "ApiKey 已 (部分) 设置 (因为是密码输入)"
    gum confirm "XrayR 安装和配置完成?"
}

install_xboard() {
    gum style --foreground 212 "--- 一键安装 Xboard 节点管理系统 ---"
    if command_exists docker; then
        echo "Docker 已经安装，跳过安装。"
    else
        gum confirm "Docker 未安装，是否现在安装？" || { echo "操作取消。"; return; }
        gum spin --title "正在安装 Docker..." -- bash <(curl -sSL https://get.docker.com) 
        sudo systemctl enable docker
        sudo systemctl start docker
    fi

    command_exists git || { sudo apt update && sudo apt install -y git; } 

    gum spin --title "正在克隆 Xboard 仓库..." -- git clone -b docker-compose --depth 1 https://github.com/cedar2025/Xboard
    cd Xboard || { echo "进入 Xboard 目录失败"; return; }
    clear

    gum spin --title "正在运行 Xboard 安装程序..." -- sudo docker compose run -it --rm xboard php artisan xboard:install 
    gum spin --title "正在启动 Xboard 服务 (后台)..." -- sudo docker compose up -d 

    local IP
    IP=$(curl -s ifconfig.me)
    gum style --foreground 212 "Xboard 节点管理系统安装成功！"
    echo "请访问: http://$IP:7001"
    cd .. 
    gum confirm "Xboard 安装完成?"
}

install_alist() {
    gum style --foreground 212 "--- 一键安装 Alist ---"
    gum spin --title "正在下载并执行 Alist 安装脚本..." -- bash -c "$(curl -fsSL \"https://alist.nn.ci/v3.sh\") install"
    
    if [ -d "/opt/alist" ]; then
        cd /opt/alist || { gum style --foreground "red" "错误: 进入 /opt/alist 目录失败。"; return 1; }
        
        local PASSWORD
        PASSWORD=$(gum input --placeholder "请输入 Alist 管理员密码" --password)
        
        gum spin --title "正在设置 Alist 管理员密码..." -- sudo ./alist admin set "$PASSWORD" 
        gum style --foreground 212 "Alist 安装并设置密码完成！"
        echo "Alist 安装目录: /opt/alist"
        echo "请使用您设置的密码登录。"
        cd - > /dev/null 
    else
        gum style --foreground "red" "错误: Alist 安装目录 /opt/alist 未找到。"
    fi
    gum confirm "Alist 安装完成?"
}

add_nginx() {
    gum style --foreground 212 "--- 添加并配置 Nginx ---"
    if ! command_exists nginx; then
        gum confirm "Nginx 未安装，是否现在安装？" || { echo "操作取消。"; return; }
        sudo apt update -y
        sudo apt install -y nginx
    fi
    
    sudo mkdir -p /etc/nginx/cert
    
    gum style --foreground "yellow" "请输入完整的公钥内容 (CERTIFICATE)，粘贴后按 Ctrl+D 保存:"
    local cert_content
    cert_content=$(gum write --placeholder "粘贴公钥内容...")
    echo "$cert_content" | sudo tee /etc/nginx/cert/cert.pem > /dev/null

    gum style --foreground "yellow" "请输入完整的私钥内容 (PRIVATE KEY)，粘贴后按 Ctrl+D 保存:"
    local key_content
    key_content=$(gum write --placeholder "粘贴私钥内容...")
    echo "$key_content" | sudo tee /etc/nginx/cert/key.pem > /dev/null
    
    local IP_PORT
    IP_PORT=$(gum input --placeholder "请输入后端服务地址和端口 (例如：http://127.0.0.1:8080)")
    local domain
    domain=$(gum input --placeholder "请输入您的域名 (例如：example.com)")

    # It's safer to back up the original nginx.conf before modifying
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup_$(date +%F_%T)
    gum style --foreground "cyan" "原 Nginx 配置文件已备份至 /etc/nginx/nginx.conf.backup_..."

    # Create a new config or replace a specific block.
    # The original script used sed -i '6,$d', which is quite aggressive.
    # A safer approach for well-structured nginx.conf is to manage site configs in sites-available/sites-enabled
    # For simplicity here, we'll try to replicate the intent by ensuring the http block exists and adding server blocks.
    # This part is tricky and highly dependent on the existing nginx.conf structure.
    # The original sed command suggests a very minimal nginx.conf.

    # We will overwrite the http block if it exists, or append if not.
    # A more robust solution would involve parsing or specific includes.

    # For this script, we'll generate a full http block and replace the existing one if found,
    # or append to a minimal conf. This is still a bit risky.
    # The original script was deleting from line 6. We'll assume a basic structure.

    local nginx_config_content
    nginx_config_content=$(cat <<EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    # ssl_dhparam /etc/nginx/dhparam.pem; # Consider generating this
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # Logging Settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    client_max_body_size 1000m;

    server {
        listen 80;
        server_name ${domain};
        # Optional: Add www to non-www redirect or vice-versa
        # if (\$host = www.${domain}) {
        #     return 301 https://.${domain}\$request_uri;
        # }
        # if (\$host = ${domain}) {
        #     return 301 https://www.${domain}\$request_uri;
        # }
        return 301 https://\$host\$request_uri;
    }

    server {
       listen 443 ssl http2;
       server_name ${domain};
       # Optional: Add www to non-www redirect or vice-versa for SSL server_name
       # server_name ${domain} www.${domain};

       ssl_certificate /etc/nginx/cert/cert.pem;
       ssl_certificate_key /etc/nginx/cert/key.pem;

        # Add security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        # add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always; # Adjust CSP as needed
        # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always; # Uncomment if you are sure about HTTPS only

        location / {
            proxy_pass ${IP_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_buffering off; # Useful for streaming applications
        }
    }
}
EOF
)
    # This replaces the whole file from 'events {' onwards. Be careful.
    # A better way is to use include directives in nginx.conf and manage server blocks in separate files.
    # For now, trying to stick to the original script's spirit of one main config file.
    # The sed command finds the line with 'events {' and replaces from there or appends if not found.
    # This is a simplified approach. A production script should be more careful.

    if grep -q "events {" /etc/nginx/nginx.conf; then
        sudo sed -i '/events {/,$d' /etc/nginx/nginx.conf # Delete from 'events {' to end of file
    else
        # If 'events {' is not found, maybe it's a very minimal conf or user deleted it.
        # We can try to truncate most of it if it's not the default.
        # The original script did sed -i '6,$d'. We'll clear most and append.
        # This assumes the first few lines are comments or `user nginx;` `worker_processes auto;` etc.
        # We will append our config after a few essential global directives.
        local current_user_line
        current_user_line=$(grep '^user' /etc/nginx/nginx.conf)
        local current_pid_line
        current_pid_line=$(grep '^pid' /etc/nginx/nginx.conf)
        local current_error_log_global
        current_error_log_global=$(grep '^error_log' /etc/nginx/nginx.conf | head -n1) # Global error_log
        local current_worker_processes
        current_worker_processes=$(grep '^worker_processes' /etc/nginx/nginx.conf)


        echo "警告: 未找到标准的 'events {' 块。将尝试追加配置。"
        echo "这可能导致非预期的 Nginx 配置。"
        echo "建议检查 /etc/nginx/nginx.conf 文件结构。"
        
        # Preserve some initial lines if they exist
        {
            echo "${current_user_line:-user www-data;}" # Default user for Ubuntu/Debian
            echo "${current_worker_processes:-worker_processes auto;}"
            echo "${current_error_log_global:-error_log /var/log/nginx/error.log warn;}"
            echo "${current_pid_line:-pid /run/nginx.pid;}"
            # Include modules-enabled, if present (common on Ubuntu/Debian)
            if [ -d /etc/nginx/modules-enabled ]; then
              echo "include /etc/nginx/modules-enabled/*.conf;"
            fi
        } | sudo tee /etc/nginx/nginx.conf > /dev/null # Overwrite with these basic settings
    fi

    echo "$nginx_config_content" | sudo tee -a /etc/nginx/nginx.conf > /dev/null
    
    gum spin --title "正在测试 Nginx 配置..." -- sudo nginx -t
    if [ $? -eq 0 ]; then
        gum spin --title "正在重载 Nginx 服务..." -- sudo nginx -s reload
        gum style --foreground 212 "Nginx 安装并配置完成！"
    else
        gum style --foreground "red" "Nginx 配置测试失败。请检查 /etc/nginx/nginx.conf"
        echo "备份文件位于 /etc/nginx/nginx.conf.backup_..."
    fi
    gum confirm "Nginx 配置完成?"
}



# --- Main Menu Logic ---
main_menu() {
    clear
    gum style \
        --border normal \
        --margin "1 2" \
        --padding "1 1" \
        --border-foreground 212 \
        "自用工具 (fq.sh - Xioaruan)"

    echo
    gum style --foreground "magenta" "请选择一个操作:"
    echo

    local choice
    choice=$(gum choose \
        "一键安装 x-ui (推荐)" \
        "一键安装 XrayR (推荐)" \
        "一键安装 Xboard 节点管理系统" \
        "一键安装 Alist" \
        "添加并配置 Nginx" \
        "退出")

    case "$choice" in
        "一键安装 x-ui (推荐)")
            install_xui
            ;;
        "一键安装 XrayR (推荐)")
            install_xrayr
            ;;
        "一键安装 Xboard 节点管理系统")
            install_xboard
            ;;
        "一键安装 Alist")
            install_alist
            ;;
        "添加并配置 Nginx")
            add_nginx
            ;;
        "退出")
            gum style --foreground "green" "脚本退出。"
            exit 0
            ;;
        *)
            # This case should ideally not be reached if gum choose is used without --no-limit
            gum style --foreground "red" "无效的选项。"
            ;;
    esac

    # After an action, ask to return to menu or exit
    if gum confirm "返回主菜单?"; then
        main_menu
    else
        gum style --foreground "green" "脚本退出。"
        exit 0
    fi
}

# Run the main menu
main_menu