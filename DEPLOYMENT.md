# 运维管理系统部署指南

## 概述

运维管理系统支持多种部署方式，适用于AlmaLinux 9.2系统：

1. **一键离线部署** - 推荐用于生产环境
2. **Docker部署** - 推荐用于容器化环境
3. **手动部署** - 用于自定义配置

## 系统要求

### 最低要求
- 操作系统: AlmaLinux 9.2 (推荐)
- CPU: 1核心
- 内存: 1GB
- 磁盘空间: 2GB
- 网络端口: 5000

### 推荐配置
- 操作系统: AlmaLinux 9.2
- CPU: 2核心
- 内存: 2GB
- 磁盘空间: 10GB
- 网络端口: 5000

## 部署方式

### 方式一：一键离线部署 (推荐)

#### 1. 准备部署包

```bash
# 在开发机器上打包
./package.sh
```

#### 2. 传输到目标服务器

```bash
# 将生成的压缩包传输到AlmaLinux 9.2服务器
scp ops-management-almalinux9.2-1.0.0.tar.gz user@server:/tmp/
```

#### 3. 在目标服务器上部署

```bash
# 解压部署包
cd /tmp
tar -xzf ops-management-almalinux9.2-1.0.0.tar.gz
cd ops-management-almalinux9.2

# 运行部署脚本
sudo ./deploy.sh
```

#### 4. 访问系统

打开浏览器访问: `http://服务器IP:5000`

默认登录信息:
- 用户名: `admin`
- 密码: `admin123`

### 方式二：Docker部署

#### 1. 准备Docker环境

```bash
# 在AlmaLinux 9.2上安装Docker
sudo dnf install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

#### 2. 部署应用

```bash
# 克隆或下载项目代码
git clone <repository-url>
cd ops-management

# 运行Docker部署脚本
sudo ./deploy-docker.sh
```

#### 3. 访问系统

打开浏览器访问: `http://服务器IP:5000`

### 方式三：手动部署

#### 1. 安装系统依赖

```bash
# 更新系统
sudo dnf update -y

# 安装Python 3.9
sudo dnf install -y python3.9 python3.9-pip python3.9-devel

# 安装其他依赖
sudo dnf install -y sqlite-devel openssl-devel libffi-devel
```

#### 2. 创建应用用户

```bash
# 创建用户
sudo useradd -r -s /bin/false -d /opt/ops-management opsuser
```

#### 3. 部署应用

```bash
# 创建目录
sudo mkdir -p /opt/ops-management
sudo chown opsuser:opsuser /opt/ops-management

# 复制应用文件
sudo cp -r . /opt/ops-management/
cd /opt/ops-management

# 创建虚拟环境
sudo -u opsuser python3.9 -m venv venv
sudo -u opsuser venv/bin/pip install -r requirements.txt
```

#### 4. 配置systemd服务

```bash
# 创建服务文件
sudo tee /etc/systemd/system/ops-management.service > /dev/null << EOF
[Unit]
Description=Ops Management System
After=network.target

[Service]
Type=simple
User=opsuser
Group=opsuser
WorkingDirectory=/opt/ops-management
Environment=PATH=/opt/ops-management/venv/bin
ExecStart=/opt/ops-management/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable ops-management
sudo systemctl start ops-management
```

## 服务管理

### 基本命令

```bash
# 启动服务
sudo systemctl start ops-management

# 停止服务
sudo systemctl stop ops-management

# 重启服务
sudo systemctl restart ops-management

# 查看状态
sudo systemctl status ops-management

# 查看日志
sudo journalctl -u ops-management -f
```

### Docker命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

## 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `FLASK_ENV` | `production` | Flask环境 |
| `SECRET_KEY` | 自动生成 | 应用密钥 |
| `DATABASE_URL` | `sqlite:///...` | 数据库连接 |

### 目录结构

```
/opt/ops-management/          # 应用主目录
├── app/                      # 应用代码
├── config/                   # 配置文件
├── data/                     # 数据库文件
├── logs/                     # 应用日志
└── venv/                     # Python虚拟环境

/var/log/ops-management/      # 系统日志
```

## 故障排除

### 常见问题

#### 1. 服务无法启动

```bash
# 检查服务状态
sudo systemctl status ops-management

# 查看详细日志
sudo journalctl -u ops-management -f

# 检查端口占用
sudo netstat -tlnp | grep 5000
```

#### 2. 数据库错误

```bash
# 检查数据库文件权限
ls -la /opt/ops-management/data/

# 重新初始化数据库
sudo -u opsuser /opt/ops-management/venv/bin/python -c "
from app import app, create_tables
with app.app_context():
    create_tables()
"
```

#### 3. 权限问题

```bash
# 检查文件权限
sudo chown -R opsuser:opsuser /opt/ops-management
sudo chmod -R 755 /opt/ops-management
```

#### 4. 防火墙问题

```bash
# 检查防火墙状态
sudo firewall-cmd --list-ports

# 开放端口
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

### 日志位置

- 应用日志: `/var/log/ops-management/app.log`
- 系统日志: `journalctl -u ops-management`
- Docker日志: `docker-compose logs`

## 安全建议

1. **修改默认密码**: 首次登录后立即修改admin密码
2. **配置防火墙**: 限制5000端口的访问范围
3. **定期备份**: 备份数据库文件和应用配置
4. **更新系统**: 定期更新系统和依赖包
5. **监控日志**: 定期检查应用和系统日志

## 卸载

### 一键卸载

```bash
sudo ./uninstall.sh
```

### 手动卸载

```bash
# 停止服务
sudo systemctl stop ops-management
sudo systemctl disable ops-management

# 删除服务文件
sudo rm /etc/systemd/system/ops-management.service
sudo systemctl daemon-reload

# 删除应用目录
sudo rm -rf /opt/ops-management
sudo rm -rf /var/log/ops-management

# 删除用户
sudo userdel opsuser
```

## 技术支持

如有问题，请检查：

1. 系统日志: `journalctl -u ops-management`
2. 应用日志: `/var/log/ops-management/app.log`
3. 服务状态: `systemctl status ops-management`
4. 端口状态: `netstat -tlnp | grep 5000`

## 更新说明

### 版本 1.0.0
- 初始版本发布
- 支持AlmaLinux 9.2
- 提供一键部署和Docker部署
- 集成systemd服务管理


