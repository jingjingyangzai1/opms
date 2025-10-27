# 运维管理系统

一个基于Flask的科技风格运维管理系统，支持资产管理、用户管理、SSH远程控制等功能。

## 功能特性

- 🔐 **用户认证**: 安全的登录/登出系统
- 🖥️ **资产管理**: 训练系统资产和主控物理服务器管理
- 🔄 **远程控制**: SSH重启和关机功能
- 📊 **实时监控**: 资产状态实时检测
- 👥 **用户管理**: 多用户权限管理
- 🎨 **科技风格**: 现代化UI设计
- 🐳 **容器化**: 支持Docker部署
- 🚀 **一键部署**: 支持AlmaLinux 9.2一键离线部署

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

## 快速开始

### 方式一：一键离线部署 (推荐)

1. **创建部署包**
```bash
./package.sh
```

2. **传输到目标服务器**
```bash
scp ops-management-almalinux9.2-1.0.0.tar.gz user@server:/tmp/
```

3. **在目标服务器上部署**
```bash
cd /tmp
tar -xzf ops-management-almalinux9.2-1.0.0.tar.gz
cd ops-management-almalinux9.2
sudo ./deploy.sh
```

4. **访问系统**
打开浏览器访问: `http://服务器IP:5000`

### 方式二：Docker部署

1. **准备Docker环境**
```bash
sudo dnf install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
```

2. **部署应用**
```bash
sudo ./deploy-docker.sh
```

3. **访问系统**
打开浏览器访问: `http://服务器IP:5000`

## 默认登录信息

- **用户名**: `admin`
- **密码**: `admin123`

⚠️ **重要**: 首次登录后请立即修改默认密码！

## 服务管理

### systemctl命令
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

## 项目结构

```
运维系统/
├── app.py                          # 主应用文件
├── config.py                       # 配置文件
├── start_app.py                    # 启动脚本
├── requirements.txt                # Python依赖
├── templates/                      # HTML模板
│   ├── base.html
│   ├── login.html
│   ├── training_assets.html
│   ├── physical_servers.html
│   └── users.html
├── deploy.sh                       # 一键部署脚本
├── uninstall.sh                    # 卸载脚本
├── package.sh                      # 打包脚本
├── deploy-docker.sh                # Docker部署脚本
├── test-deployment.sh              # 部署测试脚本
├── Dockerfile                      # Docker镜像文件
├── docker-compose.yml              # Docker Compose配置
└── DEPLOYMENT.md                   # 详细部署文档
```

## 主要功能

### 1. 资产管理
- 添加、编辑、删除资产
- 支持虚拟资产和物理资产
- 实时状态监控
- SSH远程控制（重启/关机）

### 2. 用户管理
- 多用户支持
- 密码管理
- 权限控制

### 3. 系统监控
- 资产连接状态检测
- 实时状态更新
- 日志记录

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

## 测试部署

运行测试脚本验证部署是否成功：

```bash
sudo ./test-deployment.sh
```

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

## 安全建议

1. **修改默认密码**: 首次登录后立即修改admin密码
2. **配置防火墙**: 限制5000端口的访问范围
3. **定期备份**: 备份数据库文件和应用配置
4. **更新系统**: 定期更新系统和依赖包
5. **监控日志**: 定期检查应用和系统日志

## 技术栈

- **后端**: Python 3.9, Flask 2.3.3
- **数据库**: SQLite
- **前端**: HTML5, CSS3, JavaScript, Bootstrap 5
- **部署**: systemd, Docker, Docker Compose
- **系统**: AlmaLinux 9.2

## 开发说明

### 本地开发
```bash
# 安装依赖
pip install -r requirements.txt

# 运行应用
python app.py
```

### 生产部署
```bash
# 使用systemd服务
sudo ./deploy.sh

# 或使用Docker
sudo ./deploy-docker.sh
```

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎提交Issue和Pull Request！

## 更新日志

### 版本 1.0.0
- 初始版本发布
- 支持AlmaLinux 9.2
- 提供一键部署和Docker部署
- 集成systemd服务管理
- 支持资产管理和用户管理
- 集成SSH远程控制功能