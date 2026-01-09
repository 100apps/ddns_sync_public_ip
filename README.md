# DDNS Public IP Sync Script

自动同步公网IP到DNS服务器的Shell脚本，专为PPPoE网络重启后IP变更场景设计。

[English](#english) | [中文](#中文)

---

## 中文

### 功能特性

- 🔄 自动检测公网IP变化
- 📝 完整的日志记录
- ⚙️ 灵活的配置选项
- 🔁 支持自动配置crontab定时任务
- 🌐 支持多种IP获取方式（curl / ifconfig）
- 🔌 支持主流DNS服务商API

### 使用场景

解决PPPoE拨号网络重启后公网IP变更的问题，自动更新DNS记录，确保域名始终指向最新的公网IP地址。

### 安装步骤

1. **克隆或下载本仓库**

```bash
git clone https://github.com/100apps/ddns_sync_public_ip.git
cd ddns_sync_public_ip
```

2. **配置脚本**

```bash
# 复制配置文件模板
cp ddns_config.conf.example ddns_config.conf

# 编辑配置文件
nano ddns_config.conf  # 或使用 vi/vim
```

3. **配置说明**

在 `ddns_config.conf` 中配置以下内容：

```bash
# IP获取方式：curl 或 ifconfig
IP_METHOD="curl"

# 如果使用curl方式，指定查询IP的URL
IP_CHECK_URL="https://api.ipify.org"

# 如果使用ifconfig方式，指定网络接口名称（如 ppp0）
IFCONFIG_INTERFACE="ppp0"

# DNS API配置（根据你的DNS服务商填写）
DNS_API_URL="https://api.your-dns-provider.com/update"
DNS_API_TOKEN="your_api_token_here"
DNS_RECORD_ID="your_record_id"
DNS_DOMAIN="your-domain.com"
```

### 使用方法

#### 手动运行

```bash
# 首次运行，检测IP并更新DNS
./ddns_sync_public_ip.sh

# 设置crontab定时任务（每分钟执行一次）
./ddns_sync_public_ip.sh --setup-cron
```

#### 自动运行（推荐）

运行以下命令将脚本添加到crontab，实现每分钟自动检测：

```bash
./ddns_sync_public_ip.sh --setup-cron
```

或者手动编辑crontab：

```bash
crontab -e
```

添加以下行（将路径替换为实际路径）：

```
* * * * * /path/to/ddns_sync_public_ip.sh
```

### 工作流程

1. **检查crontab**：首次运行可使用 `--setup-cron` 参数自动添加定时任务
2. **获取当前IP**：通过配置的方法获取当前公网IP地址
3. **比较IP变化**：读取上次记录的IP，如无变化则仅记录日志
4. **更新DNS记录**：如IP发生变化，调用DNS API更新记录
5. **记录结果**：成功更新后保存新IP，供下次比较使用

### 日志文件

脚本会在同目录下生成以下文件：

- `ddns_sync.log` - 运行日志文件
- `.last_ip` - 最后一次成功更新的IP记录

### 常见DNS服务商配置示例

#### Cloudflare

```bash
DNS_API_URL="https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records/YOUR_RECORD_ID"
DNS_API_TOKEN="your_cloudflare_api_token"
DNS_DOMAIN="example.com"
```

#### 阿里云（Aliyun）

```bash
DNS_API_URL="https://alidns.aliyuncs.com/"
DNS_API_TOKEN="your_access_key"
DNS_DOMAIN="example.com"
```

#### DNSPod（腾讯云）

```bash
DNS_API_URL="https://dnsapi.cn/Record.Ddns"
DNS_API_TOKEN="your_dnspod_token"
DNS_DOMAIN="example.com"
```

### 故障排查

1. **检查日志文件**：查看 `ddns_sync.log` 了解详细错误信息
2. **验证配置**：确保 `ddns_config.conf` 中的API信息正确
3. **测试IP获取**：手动运行脚本查看是否能正确获取IP
4. **检查权限**：确保脚本有执行权限（`chmod +x ddns_sync_public_ip.sh`）

---

## English

### Features

- 🔄 Automatic public IP change detection
- 📝 Complete logging functionality
- ⚙️ Flexible configuration options
- 🔁 Automatic crontab setup support
- 🌐 Multiple IP detection methods (curl / ifconfig)
- 🔌 Support for mainstream DNS provider APIs

### Use Case

Solves the problem of public IP changes after PPPoE network restarts, automatically updates DNS records to ensure your domain always points to the latest public IP address.

### Installation

1. **Clone or download this repository**

```bash
git clone https://github.com/100apps/ddns_sync_public_ip.git
cd ddns_sync_public_ip
```

2. **Configure the script**

```bash
# Copy the configuration template
cp ddns_config.conf.example ddns_config.conf

# Edit the configuration file
nano ddns_config.conf  # or use vi/vim
```

3. **Configuration Guide**

Edit `ddns_config.conf` with your settings:

```bash
# IP detection method: curl or ifconfig
IP_METHOD="curl"

# If using curl, specify the IP check URL
IP_CHECK_URL="https://api.ipify.org"

# If using ifconfig, specify the network interface (e.g., ppp0)
IFCONFIG_INTERFACE="ppp0"

# DNS API configuration (fill according to your DNS provider)
DNS_API_URL="https://api.your-dns-provider.com/update"
DNS_API_TOKEN="your_api_token_here"
DNS_RECORD_ID="your_record_id"
DNS_DOMAIN="your-domain.com"
```

### Usage

#### Manual Execution

```bash
# First run: detect IP and update DNS
./ddns_sync_public_ip.sh

# Setup crontab (runs every minute)
./ddns_sync_public_ip.sh --setup-cron
```

#### Automatic Execution (Recommended)

Run the following command to add the script to crontab for automatic checks every minute:

```bash
./ddns_sync_public_ip.sh --setup-cron
```

Or manually edit crontab:

```bash
crontab -e
```

Add this line (replace with actual path):

```
* * * * * /path/to/ddns_sync_public_ip.sh
```

### Workflow

1. **Check crontab**: Use `--setup-cron` parameter on first run to automatically add scheduled task
2. **Get current IP**: Retrieve current public IP using configured method
3. **Compare IP changes**: Read last recorded IP, log only if no change
4. **Update DNS record**: If IP changed, call DNS API to update record
5. **Record result**: Save new IP after successful update for next comparison

### Log Files

The script generates the following files in the same directory:

- `ddns_sync.log` - Operation log file
- `.last_ip` - Last successfully updated IP record

### Common DNS Provider Configuration Examples

#### Cloudflare

```bash
DNS_API_URL="https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records/YOUR_RECORD_ID"
DNS_API_TOKEN="your_cloudflare_api_token"
DNS_DOMAIN="example.com"
```

#### Aliyun

```bash
DNS_API_URL="https://alidns.aliyuncs.com/"
DNS_API_TOKEN="your_access_key"
DNS_DOMAIN="example.com"
```

#### DNSPod (Tencent Cloud)

```bash
DNS_API_URL="https://dnsapi.cn/Record.Ddns"
DNS_API_TOKEN="your_dnspod_token"
DNS_DOMAIN="example.com"
```

### Troubleshooting

1. **Check log file**: View `ddns_sync.log` for detailed error information
2. **Verify configuration**: Ensure API information in `ddns_config.conf` is correct
3. **Test IP detection**: Run script manually to check if IP can be retrieved correctly
4. **Check permissions**: Ensure script has execute permission (`chmod +x ddns_sync_public_ip.sh`)

---

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Issues and Pull Requests are welcome!

## Author

100apps
