# MyWP-Podman-Forge 🚀

**MyWP-Podman-Forge** 是一個專為 Podman 環境設計的互動式 WordPress 快速部署工具。透過簡單的 CLI 對話介面，您可以輕鬆自訂 WordPress 版本、Web 伺服器（NGINX/Apache）以及資料庫類型，並自動產生符合最佳實踐的 `docker-compose.yml` 設定檔。

[![Version](https://img.shields.io/badge/version-v1.0.0-blue.svg)](https://github.com/)
[![Podman](https://img.shields.io/badge/Podman-Supported-orange.svg)](https://podman.io/)

## 🌟 特色功能

- **互動式 TUI 介面**：使用 `whiptail` 打造，無需記憶複雜參數，跟隨選單即可完成設定。
- **多版本支援**：自由選擇 WordPress 官方版本（latest, 6.4, 6.3 等）。
- **彈性架構組合**：
  - **NGINX 穩定版**：搭配 PHP-FPM 映像檔，提供高效能的 Web 服務。
  - **Apache 2**：使用官方整合映像檔，設定最簡單。
- **資料庫自由選**：支援 **MariaDB**（建議）與 **MySQL 8.0**。
- **多實例管理**：可自訂專案名稱與外部連接埠，在同一台主機上運行多個獨立的 WordPress 網站。
- **Podman 優化**：自動處理 Registry 前綴，確保在 Podman 環境下順利拉取映像檔。

## 📋 系統需求

在開始使用之前，請確保您的系統已安裝以下工具：

- **Podman**
- **podman-compose** (可透過 `pip install podman-compose` 安裝)
- **whiptail** (通常內建於 Linux 發行版，如 `sudo apt install whiptail`)

## 🚀 快速上手

1. **下載腳本**
   ```bash
   curl -O https://raw.githubusercontent.com/YOUR_USERNAME/MyWP-Podman-Forge/main/MyWP-Podman-Forge.sh
   ```

2. **賦予執行權限**
   ```bash
   chmod +x MyWP-Podman-Forge.sh
   ```

3. **執行部署工具**
   ```bash
   ./MyWP-Podman-Forge.sh
   ```

4. **啟動容器**
   進入腳本產生的專案目錄（例如 `my-wp-site`），執行：
   ```bash
   cd my-wp-site
   podman-compose up -d
   ```

## 📂 專案結構

執行腳本後，將會建立如下結構的目錄：
```text
my-wp-site/
├── docker-compose.yml   # 容器編排設定檔
├── nginx.conf           # NGINX 設定檔 (僅在選擇 NGINX 時產生)
├── wp_data/             # WordPress 網頁程式碼持久化目錄
└── db_data/             # 資料庫持久化目錄
```

## 🛠️ 技術細節

- **網路模式**：預設使用 Podman Bridge 網路。
- **持久化**：所有資料皆儲存在專案目錄下的本地 Volume，方便備份與遷移。
- **安全性**：建議在正式環境部署後，手動修改 `docker-compose.yml` 中的資料庫密碼。

## 📄 授權協議

本專案採用 [MIT License](LICENSE) 授權。

---
**MyWP-Podman-Forge** - 讓 WordPress 在 Podman 上的部署變得優雅且簡單。
