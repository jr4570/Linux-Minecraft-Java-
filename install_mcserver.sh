#!/bin/bash

# 變數設定
SERVER_DIR="/opt/minecraft"
PAPER_JAR="paper.jar"
GEYSER_JAR="Geyser-Spigot.jar"
FLOODGATE_JAR="floodgate-spigot.jar"
JAVA_VERSION_REQUIRED=17

# 安裝必要套件
sudo apt update
sudo apt install -y curl wget jq openjdk-${JAVA_VERSION_REQUIRED}-jre-headless

# 建立伺服器目錄
sudo mkdir -p ${SERVER_DIR}
sudo chown $(whoami):$(whoami) ${SERVER_DIR}
cd ${SERVER_DIR}

# 下載最新的 PaperMC
LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
BUILD_NUMBER=$(curl -s https://api.papermc.io/v2/projects/paper/versions/${LATEST_BUILD} | jq -r '.builds[-1]')
curl -o ${PAPER_JAR} -L https://api.papermc.io/v2/projects/paper/versions/${LATEST_BUILD}/builds/${BUILD_NUMBER}/downloads/paper-${LATEST_BUILD}-${BUILD_NUMBER}.jar

# 初次啟動以生成必要檔案
java -Xms1G -Xmx2G -jar ${PAPER_JAR} --nogui || true

# 同意 EULA
echo "eula=true" > eula.txt

# 下載 Geyser-Spigot 和 Floodgate 插件
mkdir -p plugins
curl -o plugins/${GEYSER_JAR} -L https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
curl -o plugins/${FLOODGATE_JAR} -L https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot

# 配置 Geyser
GEYSER_CONFIG="plugins/Geyser-Spigot/config.yml"
if [ -f "${GEYSER_CONFIG}" ]; then
  sed -i 's/port: 19132/port: 19132/' ${GEYSER_CONFIG}
  sed -i 's/auth-type: online/auth-type: floodgate/' ${GEYSER_CONFIG}
fi

# 建立 systemd 服務
sudo tee /etc/systemd/system/minecraft.service > /dev/null <<EOF
[Unit]
Description=Minecraft PaperMC Server
After=network.target

[Service]
WorkingDirectory=${SERVER_DIR}
ExecStart=/usr/bin/java -Xms1G -Xmx2G -jar ${PAPER_JAR} --nogui
User=$(whoami)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 啟用並啟動服務
sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft

echo "✅ 安裝完成！伺服器正在運行中。"
