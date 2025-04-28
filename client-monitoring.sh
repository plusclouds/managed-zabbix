#!/bin/bash

# === Parse Arguments ===
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --server)
      ZBX_SERVER="$2"
      shift; shift
      ;;
    --tenant)
      TENANT_NAME="$2"
      shift; shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

# === Validate Required Arguments ===
if [[ -z "$ZBX_SERVER" || -z "$TENANT_NAME" ]]; then
  echo "❗ Usage: $0 --server <ZABBIX_SERVER_IP> --tenant <TENANT_NAME>"
  exit 1
fi

# === Paths and Files ===
ZBX_DIR="/etc/zabbix"
UUID_FILE="$ZBX_DIR/vm_uuid"
LOG_FILE="/var/log/zabbix/zabbix_agentd.log"
PID_DIR="/run/zabbix"
PID_FILE="$PID_DIR/zabbix_agentd.pid"

# === Create required directories ===
mkdir -p "$ZBX_DIR" /var/log/zabbix "$PID_DIR"
chown zabbix:zabbix "$PID_DIR"

# === Generate or load UUID ===
if [ ! -f "$UUID_FILE" ]; then
    UUID=$(uuidgen)
    echo "$UUID" > "$UUID_FILE"
else
    UUID=$(cat "$UUID_FILE")
fi

# === Install Zabbix agent dynamically based on Ubuntu version ===
if ! command -v zabbix_agentd &> /dev/null; then
    echo "[+] Installing Zabbix Agent..."

    # Detect Ubuntu codename
    UBUNTU_CODENAME=$(lsb_release -cs)

    # Handle special case: 24.04 (Noble) is new, Zabbix official repo may lag
    if [[ "$UBUNTU_CODENAME" == "noble" ]]; then
        echo "[!] Ubuntu 24.04 detected (noble). Trying to use 24.04 repo (experimental)."
        ZBX_RELEASE_FILE="zabbix-release_6.4-1+ubuntu24.04_all.deb"
    elif [[ "$UBUNTU_CODENAME" == "jammy" ]]; then
        echo "[+] Ubuntu 22.04 detected (jammy). Using 22.04 repo."
        ZBX_RELEASE_FILE="zabbix-release_6.4-1+ubuntu22.04_all.deb"
    else
        echo "❌ Unsupported Ubuntu version detected: $UBUNTU_CODENAME"
        exit 1
    fi

    # Download and install the matching Zabbix repo
    wget -q "https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/${ZBX_RELEASE_FILE}"
    dpkg -i "${ZBX_RELEASE_FILE}"
    apt update
    apt install -y zabbix-agent
fi

# === Write config file (unencrypted mode) ===
cat <<EOF > "$ZBX_DIR/zabbix_agentd.conf"
LogFile=$LOG_FILE
PidFile=$PID_FILE
Server=$ZBX_SERVER
ServerActive=$ZBX_SERVER
Hostname=$UUID
HostMetadata=$TENANT_NAME
EOF

# === Start the agent ===
echo "[+] Restarting Zabbix Agent with UUID: $UUID (unencrypted)"
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart zabbix-agent
systemctl enable zabbix-agent

echo "[✔] Zabbix agent is running and ready for auto-registration"
