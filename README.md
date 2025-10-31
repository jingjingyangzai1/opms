# 运维管理系统

一个基于Flask的科技风格运维管理系统，支持资产管理、用户管理、SSH远程控制等功能。

## 功能特性

- 🔐 **用户认证**: 安全的登录/登出系统，支持前后端分离
- 🖥️ **资产管理**: 训练系统资产和主控物理服务器管理
- 🔄 **远程控制**: SSH远程终端（支持自定义窗口大小）
- 📁 **文件管理**: SFTP文件上传下载，支持目录导航
- 📊 **实时监控**: 资产状态实时检测
- 👥 **用户管理**: 多用户权限管理
- 🎨 **科技风格**: 现代化UI设计
- 🐳 **容器化**: 支持Docker部署
- 🚀 **一键部署**: 支持AlmaLinux 9.2一键离线部署和Windows一键启动
- 💻 **跨平台**: 支持 Windows、Linux 系统
- 📄 **分页功能**: 资产列表支持分页浏览，每页50条记录
- 🎯 **优化界面**: 倒三角菜单优化，防止误操作删除资产

## 系统要求

### 最低要求
- 操作系统: Windows 10/11, AlmaLinux 9.2, 或其他 Linux 系统
- Python: 3.9+
- CPU: 1核心
- 内存: 1GB
- 磁盘空间: 2GB
- 网络端口: 5000

### 推荐配置
- 操作系统: Windows 10/11, AlmaLinux 9.2
- Python: 3.9+
- CPU: 2核心
- 内存: 2GB
- 磁盘空间: 10GB
- 网络端口: 5000

## 快速开始

### 方式一：Windows 快速启动（开发环境）

#### 选项A：前后端分离模式（推荐）

1. **安装后端依赖**
```bash
pip install -r requirements.txt
```

2. **安装前端依赖**
```bash
cd frontend
npm install
```

3. **一键启动所有服务**
```bash
# 使用一键启动脚本（自动启动后端和前端）
start-all.bat
```

4. **访问系统**
- 后端服务: `http://localhost:5000`
- 前端服务: `http://localhost:3000` (推荐访问此地址)
- 局域网访问: `http://你的电脑IP:3000`

#### 选项B：传统模式（仅后端）

1. **安装依赖**
```bash
pip install -r requirements.txt
```

2. **启动服务**
```bash
# 使用启动脚本（推荐）
start.bat

# 或直接运行
python run.py
```

3. **访问系统**
打开浏览器访问: `http://localhost:5000`

#### 默认登录信息
- 用户名: `admin`
- 密码: `admin123`

### 方式二：Linux 本地开发

1. **安装依赖**
```bash
pip3 install -r requirements.txt
```

2. **启动服务**
```bash
# 使用启动脚本
./start.sh

# 或直接运行
python3 app.py
```

3. **访问系统**
打开浏览器访问: `http://localhost:5000`

### 方式三：一键离线部署（生产环境）

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

### 方式四：Docker部署

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
├── app.py                          # Flask主应用文件
├── run.py                          # 运行入口脚本
├── config.py                       # 配置文件
├── start_app.py                    # 生产环境启动脚本
├── requirements.txt                # Python依赖
├── package.json                    # 前端依赖配置
├── vite.config.js                  # Vite配置文件
├── templates/                      # Flask HTML模板（后端页面）
│   ├── base.html
│   ├── login.html
│   ├── training_assets.html
│   ├── physical_servers.html
│   ├── users.html
│   ├── database_manager.html
│   └── browser_compatibility.html
├── src/                            # React前端源代码
│   ├── App.tsx                     # 主应用组件
│   ├── main.tsx                    # 入口文件
│   ├── pages/                      # 页面组件
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   └── TrainingSystemAssets.tsx
│   ├── components/                 # 通用组件
│   │   └── ProtectedRoute.tsx
│   └── contexts/                   # React Context
│       └── AuthContext.tsx
├── frontend/                       # 前端构建输出（如存在）
├── instance/                       # 实例目录
│   └── ops_management.db          # SQLite数据库
├── start.bat                       # Windows后端启动脚本
├── start-all.bat                   # Windows一键启动脚本（前后端）
├── start.sh                        # Linux启动脚本
├── deploy.sh                       # 一键部署脚本
├── uninstall.sh                    # 卸载脚本
├── package.sh                      # 打包脚本
├── deploy-docker.sh                # Docker部署脚本
├── test-deployment.sh              # 部署测试脚本
├── Dockerfile                      # Docker镜像文件
├── docker-compose.yml              # Docker Compose配置
├── README.md                       # 项目说明（本文件）
├── CHANGELOG.md                    # 更新日志
└── DEPLOYMENT.md                   # 详细部署文档
```

## 主要功能

### 1. 资产管理
- 添加、编辑、删除资产
- 支持虚拟资产和物理资产
- 实时状态监控
- SSH远程控制（重启/关机）
- SSH 终端会话管理
- **分页浏览**: 每页显示50条记录，支持快速翻页
- **操作菜单**: 更多操作菜单（编辑/删除），防止误操作
- **表格优化**: 扩大表格宽度（1600px），优化列间距

### 2. SSH 远程终端
- **交互式终端**: 完整的 SSH 终端模拟
- **自定义窗口大小**: 支持拖拽调整终端窗口大小
- **智能提示符管理**: 自动过滤冗余提示符
- **命令历史**: 保留命令执行历史
- **实时输出**: 命令执行结果实时显示
- **安全过滤**: 自动清理 ANSI 转义码和控制字符
- **防 XSS**: 输出内容自动转义，防止代码注入

### 3. SFTP 文件管理
- **文件浏览**: 浏览远程服务器文件系统，支持目录层级导航
- **文件上传**: 上传本地文件到远程服务器
- **文件下载**: 下载远程文件到本地
- **目录导航**: 支持进入子目录和返回上级目录
- **路径解析**: 自动解析用户home目录，支持 `~` 路径
- **安全传输**: 使用SFTP协议，保障文件传输安全

### 4. 用户管理
- 多用户支持
- 密码管理
- 权限控制

### 5. 系统监控
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

### Windows 本地开发
```bash
# 安装依赖
pip install -r requirements.txt

# 运行应用
python app.py

# 或使用启动脚本
start.bat
```

### Linux 本地开发
```bash
# 安装依赖
pip3 install -r requirements.txt

# 运行应用
python3 app.py

# 或使用启动脚本
./start.sh
```

### 生产部署
```bash
# Linux 使用 systemd 服务
sudo ./deploy.sh

# 或使用 Docker
sudo ./deploy-docker.sh
```

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎提交Issue和Pull Request！

## 更新日志

详细的更新日志请查看 [CHANGELOG.md](CHANGELOG.md)

### 版本 1.1.0（最新）
- ✨ 新增前后端分离架构（React + Flask）
- ✨ 新增一键启动脚本（Windows: start-all.bat）
- ✨ 资产列表新增分页功能（每页50条）
- ✨ 优化表格宽度（1600px）和列间距
- ✨ 优化更多操作菜单（编辑/删除），防止误操作
- 🔧 优化菜单展开空间，避免被滚动条遮挡
- 🔧 改进分页控件样式，符合现代化设计
- 🔧 优化缓存控制，确保页面更新及时生效

### 版本 1.0.1
- ✨ 新增 SFTP 文件管理功能
- ✨ 支持文件上传下载
- ✨ 支持目录浏览和导航（进入/返回上级）
- 🔧 改进路径解析，支持 `~` home目录
- 🔧 修复路径构建问题（`~` 和 `/` 路径处理）
- 🔧 优化 base64 编码方式，避免大文件上传栈溢出
- 🔧 改进错误处理和超时控制
- 🔧 增强文件检查逻辑（区分文件和目录）
- 🐛 修复文件上传失败问题
- 🐛 修复文件下载失败问题（路径构建和base64解码）
- 📝 更新 README 文档

### 版本 1.0.0
- 初始版本发布
- 支持AlmaLinux 9.2
- 提供一键部署和Docker部署
- 集成systemd服务管理
- 支持资产管理和用户管理
- 集成SSH远程控制功能
- 支持 SSH 终端窗口可拖拽调整大小
- 支持 SSH 终端窗口布局，内容区域自适应窗口大小
- 优化 SSH 终端提示符管理，自动过滤冗余提示符
- 修复空命令回车不清屏的问题
- 修复输入命令时在错误位置显示的问题
- 改进命令历史记录显示
- 修复多个命令执行后提示符消失的问题
- 支持 Windows 系统开发