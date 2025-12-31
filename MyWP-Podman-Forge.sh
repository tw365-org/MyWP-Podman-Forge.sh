#!/bin/bash
# Project: MyWP-Podman-Forge
# Version: v1.1.0
# Description: 互動式 WordPress Podman 部署工具 (具備自動環境檢查功能)

# --- 環境檢查與自動安裝 ---

install_tools() {
    echo "正在檢查必要工具..."
    
    # 檢查是否為 Root 或具備 sudo 權限
    SUDO=""
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            echo "錯誤: 此腳本需要 root 權限或 sudo 來安裝必要工具。"
            exit 1
        fi
    fi

    # 偵測套件管理器
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    fi

    # 安裝 whiptail
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "正在安裝 whiptail..."
        if [ "$PKG_MANAGER" == "apt" ]; then
            $SUDO apt update && $SUDO apt install -y whiptail
        else
            $SUDO $PKG_MANAGER install -y newt
        fi
    fi

    # 安裝 podman
    if ! command -v podman >/dev/null 2>&1; then
        echo "正在安裝 podman..."
        $SUDO $PKG_MANAGER install -y podman
    fi

    # 安裝 podman-compose
    if ! command -v podman-compose >/dev/null 2>&1; then
        echo "正在安裝 podman-compose..."
        if command -v pip3 >/dev/null 2>&1; then
            $SUDO pip3 install podman-compose
        elif command -v pip >/dev/null 2>&1; then
            $SUDO pip install podman-compose
        else
            echo "正在安裝 python3-pip..."
            if [ "$PKG_MANAGER" == "apt" ]; then
                $SUDO apt update && $SUDO apt install -y python3-pip
            else
                $SUDO $PKG_MANAGER install -y python3-pip
            fi
            $SUDO pip3 install podman-compose
        fi
    fi
}

# 執行安裝檢查
install_tools

# --- 互動式部署介面 ---

# 標題與版本
TITLE="MyWP-Podman-Forge v1.1.0"

# 1. 輸入專案名稱
PROJECT_NAME=$(whiptail --title "$TITLE" --inputbox "請輸入專案名稱 (將建立同名資料夾):" 10 60 "my-wp-site" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then exit; fi

# 2. 選擇 WordPress 版本
WP_VERSION=$(whiptail --title "$TITLE" --menu "請選擇 WordPress 版本:" 15 60 5 \
"latest" "最新穩定版 (預設)" \
"6.4" "WordPress 6.4" \
"6.3" "WordPress 6.3" \
"6.2" "WordPress 6.2" \
"6.1" "WordPress 6.1" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then exit; fi

# 3. 選擇 Web Server
WEB_SERVER=$(whiptail --title "$TITLE" --menu "請選擇 Web Server:" 15 60 2 \
"NGINX" "NGINX 穩定版 (搭配 PHP-FPM)" \
"APACHE2" "Apache 2 (內建於 WordPress 映像檔)" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then exit; fi

# 4. 選擇資料庫
DB_TYPE=$(whiptail --title "$TITLE" --menu "請選擇資料庫類型:" 15 60 2 \
"mariadb" "MariaDB 穩定版 (建議)" \
"mysql" "MySQL 8.0" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then exit; fi

# 5. 輸入外部連接埠
HOST_PORT=$(whiptail --title "$TITLE" --inputbox "請輸入外部存取連接埠 (Port):" 10 60 "8080" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then exit; fi

# 建立專案目錄
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# 映像檔前綴處理
REGISTRY="docker.io/library"

# 準備 Compose 內容
cat <<EOF > docker-compose.yml
services:
  db:
    image: ${REGISTRY}/${DB_TYPE}:latest
    container_name: ${PROJECT_NAME}_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: wordpress_root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress_user
      MYSQL_PASSWORD: wordpress_password
    volumes:
      - ./db_data:/var/lib/mysql

EOF

if [ "$WEB_SERVER" == "APACHE2" ]; then
    cat <<EOF >> docker-compose.yml
  wordpress:
    image: ${REGISTRY}/wordpress:${WP_VERSION}
    container_name: ${PROJECT_NAME}_wp
    restart: always
    ports:
      - "${HOST_PORT}:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress_user
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./wp_data:/var/www/html
    depends_on:
      - db
EOF
else
    cat <<EOF >> docker-compose.yml
  wordpress:
    image: ${REGISTRY}/wordpress:${WP_VERSION}-fpm
    container_name: ${PROJECT_NAME}_wp
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress_user
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./wp_data:/var/www/html
    depends_on:
      - db

  nginx:
    image: ${REGISTRY}/nginx:stable
    container_name: ${PROJECT_NAME}_nginx
    restart: always
    ports:
      - "${HOST_PORT}:80"
    volumes:
      - ./wp_data:/var/www/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - wordpress
EOF

    cat <<'EOF' > nginx.conf
server {
    listen 80;
    server_name localhost;

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
EOF
fi

# 完成提示
whiptail --title "部署成功" --msgbox "MyWP-Podman-Forge 已完成設定！\n\n專案目錄：$PROJECT_NAME\n外部連接埠：$HOST_PORT\n\n啟動命令：\ncd $PROJECT_NAME && podman-compose up -d" 15 60
