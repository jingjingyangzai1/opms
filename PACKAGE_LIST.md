# 运维管理系统部署包清单

## 文件结构

```
运维系统/
├── app.py                          # 主应用文件
├── config.py                       # 配置文件
├── run.py                          # 运行脚本
├── start_app.py                    # 启动脚本
├── requirements.txt                # Python依赖
├── templates/                      # HTML模板
│   ├── base.html
│   ├── login.html
│   ├── training_assets.html
│   ├── physical_servers.html
│   └── users.html
├── instance/                       # 实例目录
│   └── ops_management.db          # SQLite数据库
├── static/                         # 静态文件(如果存在)
├── deploy.sh                       # 一键部署脚本
├── uninstall.sh                    # 卸载脚本
├── package.sh                      # 打包脚本
├── deploy-docker.sh                # Docker部署脚本
├── Dockerfile                      # Docker镜像文件
├── docker-compose.yml              # Docker Compose配置
├── setup-permissions.bat           # Windows权限设置脚本
├── DEPLOYMENT.md                   # 部署文档
├── PACKAGE_LIST.md                 # 本文件
└── README.md                       # 项目说明
```

## 部署方式

### 1. 一键离线部署 (推荐)

**适用场景**: 生产环境，需要systemctl服务管理

**步骤**:
1. 运行 `./package.sh` 创建部署包
2. 将生成的 `ops-management-almalinux9.2-1.0.0.tar.gz` 传输到目标服务器
3. 在目标服务器上解压并运行 `sudo ./deploy.sh`

**特点**:
- 自动安装系统依赖
- 创建专用用户和目录
- 配置systemd服务
- 开机自启动
- 完整的日志管理

### 2. Docker部署

**适用场景**: 容器化环境，需要快速部署

**步骤**:
1. 确保目标服务器已安装Docker和Docker Compose
2. 运行 `sudo ./deploy-docker.sh`

**特点**:
- 容器化部署
- 环境隔离
- 易于扩展
- 支持Docker Compose管理

### 3. 手动部署

**适用场景**: 需要自定义配置

**步骤**:
1. 手动安装系统依赖
2. 创建用户和目录
3. 复制应用文件
4. 配置systemd服务

## 系统要求

### 最低要求
- 操作系统: AlmaLinux 9.2
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

## 访问信息

- **访问地址**: `http://服务器IP:5000`
- **默认用户名**: `admin`
- **默认密码**: `admin123`

## 目录结构

### 一键部署后的目录结构
```
/opt/ops-management/          # 应用主目录
├── app/                      # 应用代码
├── config/                   # 配置文件
├── data/                     # 数据库文件
├── logs/                     # 应用日志
└── venv/                     # Python虚拟环境

/var/log/ops-management/      # 系统日志
```

### Docker部署后的目录结构
```
./data/                       # 数据目录
./logs/                       # 日志目录
/var/log/ops-management/      # 系统日志
```

## 配置文件

### 环境变量
- `FLASK_ENV`: Flask环境 (production)
- `SECRET_KEY`: 应用密钥 (自动生成)
- `DATABASE_URL`: 数据库连接 (SQLite)

### 日志配置
- 应用日志: `/var/log/ops-management/app.log`
- 系统日志: `journalctl -u ops-management`
- Docker日志: `docker-compose logs`

## 安全建议

1. **修改默认密码**: 首次登录后立即修改admin密码
2. **配置防火墙**: 限制5000端口的访问范围
3. **定期备份**: 备份数据库文件和应用配置
4. **更新系统**: 定期更新系统和依赖包
5. **监控日志**: 定期检查应用和系统日志

## 故障排除

### 常见问题
1. **服务无法启动**: 检查systemctl状态和日志
2. **数据库错误**: 检查文件权限和数据库文件
3. **权限问题**: 检查文件所有者和权限设置
4. **防火墙问题**: 检查端口开放状态

### 日志位置
- 应用日志: `/var/log/ops-management/app.log`
- 系统日志: `journalctl -u ops-management -f`
- Docker日志: `docker-compose logs -f`

## 更新和卸载

### 更新
1. 停止服务
2. 备份数据
3. 替换应用文件
4. 重启服务

### 卸载
- **一键卸载**: `sudo ./uninstall.sh`
- **手动卸载**: 删除相关文件和目录

## 技术支持

如有问题，请检查：
1. 系统日志
2. 应用日志
3. 服务状态
4. 端口状态
5. 文件权限


