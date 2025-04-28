# Zabbix Monitoring Agent Installation Script

This script installs and configures the Zabbix Agent for tenant-based auto-registration into a centralized Zabbix monitoring system.

------

## 📋 Features

- Automatic UUID generation per VM
- Dynamic Ubuntu version detection
- Zabbix Agent installation from official repository
- Basic agent configuration with Hostname (UUID) and HostMetadata (tenant name)
- Ready for manual PSK encryption setup later
- No hardcoded server addresses or tenant names — everything is passed dynamically

------

## ⚙️ Usage

```
sudo ./monitoring.sh --server <ZABBIX_SERVER_IP> --tenant <TENANT_NAME>
```

- `--server`: IP address or hostname of your Zabbix server
- `--tenant`: The tenant name to be used as HostMetadata

------

## 🛠 Example

```
sudo ./monitoring.sh --server 192.168.1.104 --tenant Tenant_Test
```

This will:

- Install the Zabbix Agent (version 6.4)
- Configure it to communicate with `192.168.1.104`
- Set the HostMetadata to `Tenant_Test`
- Generate and save a unique UUID for the VM
- Start and enable the Zabbix Agent service

------

## 🧩 Requirements

- Ubuntu 22.04 LTS (Jammy) or 24.04 LTS (Noble)
- Internet access to download Zabbix repositories
- Root/sudo privileges

------

## 🚨 Notes

- **This script does not configure TLS/PSK encryption yet.**
   The Zabbix Server must be configured manually or via API after agent registration.
- **This script is optimized for auto-registration setups** — make sure a corresponding auto-registration rule exists in your Zabbix server.
- `/etc/zabbix/vm_uuid` will store the unique identifier for the VM.
- `/var/log/zabbix/zabbix_agentd.log` will be used for agent logs.