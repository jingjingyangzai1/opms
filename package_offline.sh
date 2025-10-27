#!/bin/bash

# 运维管理系统离线部署包打包脚本
# 支持Windows、Linux、AlmaLinux等多种操作系统
# 打包所有Python依赖，适用于纯内网环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PACKAGE_NAME="ops-management-offline"
PACKAGE_VERSION="1.0.2"
BUILD_DIR="build"
PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"
CURRENT_DIR=$(pwd)

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_step "检查依赖..."
    
    if ! command -v pip &> /dev/null; then
        log_error "pip未安装，请先安装pip"
        exit 1
    fi
    
    log_info "依赖检查完成"
}

# 清理构建目录
clean_build() {
    log_step "清理构建目录..."
    
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$PACKAGE_DIR"
    log_info "构建目录已清理"
}

# 下载Python依赖包
download_python_packages() {
    log_step "下载Python依赖包..."
    
    # 创建pip缓存目录
    mkdir -p "$PACKAGE_DIR/packages"
    
    # 下载所有依赖包（包括依赖的依赖）
    pip download -r requirements.txt -d "$PACKAGE_DIR/packages" \
        --platform linux_x86_64 \
        --platform win_amd64 \
        --only-binary=:all: || {
        # 如果平台限定失败，则下载通用包
        pip download -r requirements.txt -d "$PACKAGE_DIR/packages"
    }
    
    log_info "Python依赖包下载完成 ($(ls -1 "$PACKAGE_DIR/packages" | wc -l) 个文件)"
}

# 复制应用文件
copy_app_files() {
    log_step "复制应用文件..."
    
    # 复制Python文件
    cp app.py "$PACKAGE_DIR/"
    cp config.py "$PACKAGE_DIR/"
    if [[ -f "run.py" ]]; then
        cp run.py "$PACKAGE_DIR/"
    fi
    if [[ -f "start_app.py" ]]; then
        cp start_app.py "$PACKAGE_DIR/"
    fi
    cp requirements.txt "$PACKAGE_DIR/"
    
    # 复制模板目录
    if [[ -d "templates" ]]; then
        cp -r templates "$PACKAGE_DIR/"
    fi
    
    # 复制静态文件目录
    if [[ -d "static" ]]; then
        cp -r static "$PACKAGE_DIR/"
    fi
    
    # 复制实例目录
    if [[ -d "instance" ]]; then
        cp -r instance "$PACKAGE_DIR/"
    fi
    
    log_info "应用文件复制完成"
}

# 复制部署脚本
copy_deploy_scripts() {
    log_step "复制部署脚本..."
    
    # Linux部署脚本
    if [[ -f "deploy.sh" ]]; then
        cp deploy.sh "$PACKAGE_DIR/"
    fi
    
    # Windows部署脚本
    if [[ -f "deploy.bat" ]]; then
        cp deploy.bat "$PACKAGE_DIR/"
    fi
    
    if [[ -f "start.bat" ]]; then
        cp start.bat "$PACKAGE_DIR/"
    fi
    
    if [[ -f "start.sh" ]]; then
        cp start.sh "$PACKAGE_DIR/"
    fi
    
    # 卸载脚本
    if [[ -f "uninstall.sh" ]]; then
        cp uninstall.sh "$PACKAGE_DIR/"
    fi
    
    # 设置执行权限
    find "$PACKAGE_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    
    log_info "部署脚本复制完成"
}

# 创建跨平台部署说明
create_deploy_readme() {
    log_step "创建部署说明文件..."
    
    cat > "$PACKAGE_DIR/DEPLOY_OFFLINE.md" << 'EOF'
# 运维管理系统 - 离线部署包

## 系统要求

### Linux 系统
- RHEL 7/8/9 / CentOS 7/8 / AlmaLinux 7/8/9 / Rocky Linux
- Ubuntu 18.04+ / Debian 10+
- Python 3.7+
- 最小内存: 1GB
- 最小磁盘空间: 2GB
- 网络端口: 5000

### Windows 系统
- Windows 10/11
- Python 3.7+
- 最小内存: 1GB
- 最小磁盘空间: 2GB
- 网络端口: 5000

## 快速部署

### 方式一：Linux 系统部署

1. **解压部署包**
```bash
tar -xzf ops-management-offline-1.0.2.tar.gz
cd ops-management-offline
```

2. **安装Python依赖（离线）**
```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 离线安装依赖
pip install --no-index --find-links=./packages -r requirements.txt
```

3. **运行部署脚本（可选）**
```bash
# 如果有deploy.sh脚本
chmod +x deploy.sh
sudo ./deploy.sh
```

4. **启动服务**
```bash
# 使用系统服务（推荐）
systemctl start ops-management

# 或直接运行
python app.py
```

### 方式二：Windows 系统部署

1. **解压部署包**
```cmd
tar -xzf ops-management-offline-1.0.2.tar.gz
cd ops-management-offline
```

2. **安装Python依赖（离线）**
```cmd
REM 创建虚拟环境
python -m venv venv

REM 激活虚拟环境
venv\Scripts\activate

REM 离线安装依赖
pip install --no-index --find-links=.\packages -r requirements.txt
```

3. **启动服务**
```cmd
REM 使用启动脚本
start.bat

REM 或直接运行
python app.py
```

## 手动部署（无自动化脚本）

### Linux 系统

1. **创建虚拟环境**
```bash
python3 -m venv venv
source venv/bin/activate
```

2. **离线安装依赖**
```bash
pip install --no-index --find-links=./packages -r requirements.txt
```

3. **初始化数据库**
```bash
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
```

4. **运行服务**
```bash
python app.py
```

### Windows 系统

1. **创建虚拟环境**
```cmd
python -m venv venv
venv\Scripts\activate
```

2. **离线安装依赖**
```cmd
pip install --no-index --find-links=.\packages -r requirements.txt
```

3. **初始化数据库**
```cmd
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
```

4. **运行服务**
```cmd
python app.py
```

## 访问系统

部署完成后，打开浏览器访问：
- Linux: `http://服务器IP:5000`
- Windows: `http://localhost:5000`

默认登录信息:
- 用户名: `admin`
- 密码: `admin123`

⚠️ **重要**: 首次登录后请立即修改默认密码！

## 目录结构

```
ops-management-offline/
├── packages/              # Python依赖包
├── templates/             # HTML模板
├── static/               # 静态文件
├── instance/             # 实例配置
├── app.py                # 主应用文件
├── config.py             # 配置文件
├── requirements.txt      # Python依赖列表
├── deploy.sh             # Linux部署脚本
├── start.bat             # Windows启动脚本
├── start.sh              # Linux启动脚本
└── DEPLOY_OFFLINE.md     # 本文件
```

## 故障排除

### 1. pip install 失败

如果离线安装失败，可以尝试：
```bash
# 使用本地包
pip install --no-index --find-links=./packages -r requirements.txt

# 或逐个安装
cd packages
pip install *.whl
```

### 2. 端口被占用

```bash
# Linux
sudo netstat -tlnp | grep 5000
sudo kill -9 <PID>

# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

### 3. Python 版本不兼容

确保Python版本 >= 3.7:
```bash
python3 --version
```

### 4. 权限问题

```bash
# Linux
chmod +x deploy.sh
sudo chown -R $USER:$USER .

# Windows
# 以管理员身份运行
```

## 离线环境注意事项

1. **Python版本**: 确保目标系统已安装Python 3.7+
2. **操作系统**: 包中已包含Windows和Linux的二进制包
3. **架构**: 包中包含 x86_64 架构的二进制文件
4. **网络**: 部署过程中无需联网

## 技术支持

如有问题，请检查日志或联系技术支持。
EOF

    log_info "部署说明文件创建完成"
}

# 创建Windows部署脚本
create_windows_deploy_script() {
    log_step "创建Windows部署脚本..."
    
    cat > "$PACKAGE_DIR/deploy_offline.bat" << 'EOF'
@echo off
chcp 65001 >nul
echo ==========================================
echo  运维管理系统离线部署脚本 (Windows)
echo ==========================================
echo.

REM 检查Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python未安装或未添加到PATH
    echo 请安装Python 3.7+并添加到系统PATH
    pause
    exit /b 1
)

echo [INFO] 检测到Python:
python --version

REM 检查是否已有虚拟环境
if exist "venv" (
    echo [INFO] 虚拟环境已存在
) else (
    echo [STEP] 创建虚拟环境...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo [ERROR] 虚拟环境创建失败
        pause
        exit /b 1
    )
    echo [INFO] 虚拟环境创建成功
)

REM 激活虚拟环境
echo [STEP] 激活虚拟环境...
call venv\Scripts\activate.bat

REM 升级pip
echo [STEP] 升级pip...
python -m pip install --upgrade pip --no-index --find-links=.\packages

REM 离线安装依赖
echo [STEP] 离线安装Python依赖包...
pip install --no-index --find-links=.\packages -r requirements.txt

if %errorlevel% neq 0 (
    echo [ERROR] Python依赖安装失败
    echo [INFO] 请检查packages目录是否存在依赖包
    pause
    exit /b 1
)

echo [INFO] Python依赖安装完成

REM 初始化数据库
echo [STEP] 初始化数据库...
python -c "from app import app, create_tables; app.app_context().push(); create_tables()"
if %errorlevel% neq 0 (
    echo [WARN] 数据库初始化失败，但可以继续
)

echo.
echo ==========================================
echo  部署完成！
echo ==========================================
echo 启动服务:
echo   start.bat
echo 或
echo   python app.py
echo.
echo 访问地址: http://localhost:5000
echo 默认账号: admin / admin123
echo ==========================================
pause
EOF

    log_info "Windows部署脚本创建完成"
}

# 创建Linux部署脚本
create_linux_deploy_script() {
    log_step "创建Linux部署脚本..."
    
    cat > "$PACKAGE_DIR/deploy_offline.sh" << 'EOF'
#!/bin/bash

# 运维管理系统离线部署脚本 (Linux)
# 适用于纯内网环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查Python
log_step "检查Python..."
if ! command -v python3 &> /dev/null; then
    log_error "Python3未安装"
    echo "请安装Python 3.7+:"
    echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip python3-venv"
    echo "  RHEL/CentOS: sudo yum install python3 python3-pip"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
log_info "检测到Python: $PYTHON_VERSION"

# 检查是否已有虚拟环境
if [[ -d "venv" ]]; then
    log_info "虚拟环境已存在"
else
    log_step "创建虚拟环境..."
    python3 -m venv venv
    log_info "虚拟环境创建成功"
fi

# 激活虚拟环境
log_step "激活虚拟环境..."
source venv/bin/activate

# 升级pip
log_step "升级pip..."
python -m pip install --upgrade pip --no-index --find-links=./packages

# 离线安装依赖
log_step "离线安装Python依赖包..."
pip install --no-index --find-links=./packages -r requirements.txt

if [[ $? -ne 0 ]]; then
    log_error "Python依赖安装失败"
    log_warn "请检查packages目录是否存在依赖包"
    exit 1
fi

log_info "Python依赖安装完成"

# 初始化数据库
log_step "初始化数据库..."
python -c "from app import app, create_tables; app.app_context().push(); create_tables()" || {
    log_warn "数据库初始化失败，但可以继续"
}

echo ""
echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo "启动服务:"
echo "  ./start.sh"
echo "或"
echo "  python app.py"
echo ""
echo "访问地址: http://localhost:5000"
echo "默认账号: admin / admin123"
echo "=========================================="
EOF

    chmod +x "$PACKAGE_DIR/deploy_offline.sh"
    log_info "Linux部署脚本创建完成"
}

# 创建版本信息文件
create_version_info() {
    log_step "创建版本信息文件..."
    
    cat > "$PACKAGE_DIR/VERSION" << EOF
PACKAGE_NAME=$PACKAGE_NAME
PACKAGE_VERSION=$PACKAGE_VERSION
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_HOST=$(hostname)
PYTHON_VERSION=3.7+
FLASK_VERSION=2.3.3
SUPPORT_OS=Windows,Linux,AlmaLinux,RHEL,CentOS,Ubuntu,Debian
OFFLINE_DEPLOY=YES
EOF

    log_info "版本信息文件创建完成"
}

# 创建压缩包
create_archive() {
    log_step "创建压缩包..."
    
    cd "$BUILD_DIR"
    tar -czf "${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz" "$PACKAGE_NAME"
    
    # 计算文件大小和校验和
    PACKAGE_FILE="${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"
    PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
    PACKAGE_CHECKSUM=$(sha256sum "$PACKAGE_FILE" | cut -d' ' -f1)
    
    log_info "压缩包创建完成: $PACKAGE_FILE"
    log_info "文件大小: $PACKAGE_SIZE"
    log_info "SHA256: $PACKAGE_CHECKSUM"
    
    # 保存校验和
    echo "$PACKAGE_CHECKSUM" > "${PACKAGE_FILE}.sha256"
    log_info "校验和文件已保存: ${PACKAGE_FILE}.sha256"
}

# 显示打包信息
show_package_info() {
    log_step "打包完成信息"
    
    echo
    echo "=========================================="
    echo "  运维管理系统离线部署包"
    echo "  打包完成"
    echo "=========================================="
    echo "包名称: $PACKAGE_NAME"
    echo "版本: $PACKAGE_VERSION"
    echo "构建目录: $BUILD_DIR"
    echo "压缩包: $BUILD_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"
    echo "校验和: $BUILD_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz.sha256"
    echo
    echo "部署步骤（Linux）:"
    echo "1. 传输: scp ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz user@server:/tmp/"
    echo "2. 解压: tar -xzf ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"
    echo "3. 进入: cd ${PACKAGE_NAME}"
    echo "4. 运行: chmod +x deploy_offline.sh && ./deploy_offline.sh"
    echo "5. 启动: python app.py"
    echo
    echo "部署步骤（Windows）:"
    echo "1. 解压到目标目录"
    echo "2. 运行: deploy_offline.bat"
    echo "3. 启动: start.bat"
    echo
    echo "支持的平台: Windows, Linux, RHEL, CentOS, AlmaLinux, Ubuntu, Debian"
    echo "部署方式: 纯离线（无需互联网连接）"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统离线部署包打包脚本"
    echo "  支持跨平台，纯内网部署"
    echo "=========================================="
    echo
    
    check_dependencies
    clean_build
    copy_app_files
    copy_deploy_scripts
    download_python_packages
    create_deploy_readme
    create_windows_deploy_script
    create_linux_deploy_script
    create_version_info
    create_archive
    show_package_info
    
    log_info "打包完成！"
}

# 执行主函数
main "$@"

