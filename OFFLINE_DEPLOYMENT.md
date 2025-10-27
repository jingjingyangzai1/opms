# 离线部署指南

## 概述

运维管理系统支持纯内网环境的离线部署。该方案适用于没有互联网连接的内网环境，如：
- 政府部门内部网络
- 企业内网隔离环境
- 生产环境的安全区
- 离线服务器集群

## 快速开始

### 第一步：创建离线部署包（在联网机器上）

```bash
# 克隆或下载项目到联网机器
# 在项目根目录执行
./package_offline.sh
```

这会生成一个包含所有依赖的离线包：
```
build/ops-management-offline-1.0.2.tar.gz
```

### 第二步：传输到内网服务器

#### Linux系统
```bash
# 使用U盘、光盘或其他物理介质
# 或者通过隔离的网络传输
scp ops-management-offline-1.0.2.tar.gz user@server:/tmp/
```

#### Windows系统
- 使用U盘复制到目标机器
- 通过内网文件共享传输

### 第三步：在内网服务器上部署

#### Linux系统部署

```bash
# 解压
tar -xzf ops-management-offline-1.0.2.tar.gz
cd ops-management-offline

# 运行部署脚本
chmod +x deploy_offline.sh
./deploy_offline.sh
```

#### Windows系统部署

```cmd
REM 解压到目标目录（如C:\ops-management）

REM 打开命令提示符（cmd）
cd C:\ops-management

REM 运行部署脚本
deploy_offline.bat
```

### 第四步：启动服务

#### Linux
```bash
# 使用systemd服务
sudo systemctl start ops-management

# 或直接运行
python app.py
```

#### Windows
```cmd
REM 使用启动脚本
start.bat

REM 或直接运行
python app.py
```

## 详细部署步骤

### Linux系统

#### 环境要求
- Python 3.7+
- 最小内存：1GB
- 最小磁盘空间：2GB

#### 安装步骤

1. **解压部署包**
```bash
tar -xzf ops-management-offline-1.0.2.tar.gz
cd ops-management-offline
```

2. **创建虚拟环境（可选但推荐）**
```bash
python3 -m venv venv
source venv/bin/activate
```

3. **离线安装Python依赖**
```bash
# 使用打包好的依赖包
pip install --no-index --find-links=./packages -r requirements.txt
```

4. **初始化数据库**
```bash
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
```

5. **配置服务（可选）**
```bash
# 如果有deploy.sh脚本
chmod +x deploy.sh
sudo ./deploy.sh
```

6. **启动服务**
```bash
# 使用systemd
sudo systemctl start ops-management

# 或直接运行
python app.py
```

### Windows系统

#### 环境要求
- Python 3.7+
- Windows 10/11
- 最小内存：1GB
- 最小磁盘空间：2GB

#### 安装步骤

1. **解压部署包**
```cmd
REM 解压到 C:\ops-management
```

2. **打开命令提示符**
```cmd
cd C:\ops-management
```

3. **创建虚拟环境（可选但推荐）**
```cmd
python -m venv venv
venv\Scripts\activate
```

4. **离线安装Python依赖**
```cmd
pip install --no-index --find-links=.\packages -r requirements.txt
```

5. **初始化数据库**
```cmd
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
```

6. **启动服务**
```cmd
REM 使用启动脚本
start.bat

REM 或直接运行
python app.py
```

## 支持的平台

### Linux发行版
- RHEL 7/8/9
- CentOS 7/8
- AlmaLinux 7/8/9
- Rocky Linux
- Ubuntu 18.04+
- Debian 10+
- openSUSE
- 其他支持Python 3.7+的Linux系统

### Windows版本
- Windows 10
- Windows 11
- Windows Server 2016+
- Windows Server 2019+
- Windows Server 2022

### 系统架构
- x86_64 (64位)
- AMD64 (64位)

## 离线部署特点

1. **无需互联网连接**
   - 所有Python依赖包已打包
   - 部署过程完全离线

2. **跨平台支持**
   - Windows和Linux通用包
   - 自动检测系统类型

3. **自动化部署**
   - Linux: `deploy_offline.sh`
   - Windows: `deploy_offline.bat`
   - 一键完成所有配置

4. **依赖管理**
   - 预打包的wheel文件
   - 版本锁定，避免依赖冲突

## 验证部署

### Linux系统
```bash
# 检查服务状态
systemctl status ops-management

# 检查日志
journalctl -u ops-management -f

# 测试端口
curl http://localhost:5000
```

### Windows系统
```cmd
REM 检查Python进程
tasklist | findstr python

REM 测试端口
curl http://localhost:5000
```

访问系统：`http://服务器IP:5000`
- 用户名: `admin`
- 密码: `admin123`

## 故障排除

### 问题1: pip install失败

**Linux:**
```bash
# 尝试使用本地包
cd packages
pip install *.whl

# 或手动安装
pip install --no-index --find-links=. -r ../requirements.txt
```

**Windows:**
```cmd
cd packages
pip install *.whl
cd ..
pip install --no-index --find-links=.\packages -r requirements.txt
```

### 问题2: Python版本不兼容

确保Python版本 >= 3.7:
```bash
# Linux
python3 --version

# Windows
python --version
```

### 问题3: 权限问题

**Linux:**
```bash
# 给脚本执行权限
chmod +x *.sh

# 修复文件所有权
sudo chown -R $USER:$USER .
```

**Windows:**
- 以管理员身份运行命令提示符

### 问题4: 端口被占用

**Linux:**
```bash
sudo netstat -tlnp | grep 5000
sudo kill -9 <PID>
```

**Windows:**
```cmd
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

### 问题5: 数据库初始化失败

```bash
# Linux
rm instance/ops_management.db
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"

# Windows
del instance\ops_management.db
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
```

## 性能优化

1. **使用systemd服务**（Linux）
2. **配置自动启动**（可选）
3. **设置防火墙规则**
4. **定期备份数据库**

## 安全建议

1. **修改默认密码**
2. **配置HTTPS**（推荐）
3. **限制访问IP**
4. **定期备份数据**
5. **监控日志文件**

## 技术支持

如有问题，请查看：
1. 日志文件：`logs/ops_management.log`
2. README.md 文件
3. 联系技术支持

## 更新日志

- **1.0.2**: 新增离线部署功能
- **1.0.1**: SFTP文件管理
- **1.0.0**: 初始版本

