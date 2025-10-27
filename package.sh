#!/bin/bash

# 运维管理系统打包脚本
# 创建离线部署包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PACKAGE_NAME="ops-management-almalinux9.2"
PACKAGE_VERSION="1.0.0"
BUILD_DIR="build"
PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"

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

# 清理构建目录
clean_build() {
    log_step "清理构建目录..."
    
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$PACKAGE_DIR"
    log_info "构建目录已清理"
}

# 复制应用文件
copy_app_files() {
    log_step "复制应用文件..."
    
    # 复制Python文件
    cp app.py "$PACKAGE_DIR/"
    cp config.py "$PACKAGE_DIR/"
    cp run.py "$PACKAGE_DIR/"
    cp start_app.py "$PACKAGE_DIR/"
    cp requirements.txt "$PACKAGE_DIR/"
    
    # 复制模板目录
    cp -r templates "$PACKAGE_DIR/"
    
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
    
    cp deploy.sh "$PACKAGE_DIR/"
    cp uninstall.sh "$PACKAGE_DIR/"
    
    # 设置执行权限
    chmod +x "$PACKAGE_DIR/deploy.sh"
    chmod +x "$PACKAGE_DIR/uninstall.sh"
    chmod +x "$PACKAGE_DIR/start_app.py"
    
    log_info "部署脚本复制完成"
}

# 创建README文件
create_readme() {
    log_step "创建README文件..."
    
    cat > "$PACKAGE_DIR/README.md" << 'EOF'
# 运维管理系统 - AlmaLinux 9.2 离线部署包

## 系统要求

- AlmaLinux 9.2 (推荐)
- 最小内存: 1GB
- 最小磁盘空间: 2GB
- 网络端口: 5000

## 快速部署

1. 解压部署包
```bash
tar -xzf ops-management-almalinux9.2-1.0.0.tar.gz
cd ops-management-almalinux9.2
```

2. 运行部署脚本
```bash
sudo ./deploy.sh
```

3. 访问系统
打开浏览器访问: http://服务器IP:5000

默认登录信息:
- 用户名: admin
- 密码: admin123

## 服务管理

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

## 卸载

```bash
sudo ./uninstall.sh
```

## 目录结构

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

1. 检查服务状态
```bash
sudo systemctl status ops-management
```

2. 查看详细日志
```bash
sudo journalctl -u ops-management -f
```

3. 检查端口占用
```bash
sudo netstat -tlnp | grep 5000
```

4. 检查防火墙
```bash
sudo firewall-cmd --list-ports
```

## 技术支持

如有问题，请检查日志文件或联系技术支持。
EOF

    log_info "README文件创建完成"
}

# 创建版本信息文件
create_version_info() {
    log_step "创建版本信息文件..."
    
    cat > "$PACKAGE_DIR/VERSION" << EOF
PACKAGE_NAME=$PACKAGE_NAME
PACKAGE_VERSION=$PACKAGE_VERSION
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_HOST=$(hostname)
PYTHON_VERSION=3.9
FLASK_VERSION=2.3.3
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
}

# 显示打包信息
show_package_info() {
    log_step "打包完成信息"
    
    echo
    echo "=========================================="
    echo "  运维管理系统打包完成"
    echo "=========================================="
    echo "包名称: $PACKAGE_NAME"
    echo "版本: $PACKAGE_VERSION"
    echo "构建目录: $BUILD_DIR"
    echo "压缩包: $BUILD_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"
    echo
    echo "部署步骤:"
    echo "1. 将压缩包传输到AlmaLinux 9.2服务器"
    echo "2. 解压: tar -xzf ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"
    echo "3. 进入目录: cd $PACKAGE_NAME"
    echo "4. 运行部署: sudo ./deploy.sh"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统打包脚本"
    echo "  创建离线部署包"
    echo "=========================================="
    echo
    
    clean_build
    copy_app_files
    copy_deploy_scripts
    create_readme
    create_version_info
    create_archive
    show_package_info
    
    log_info "打包完成！"
}

# 执行主函数
main "$@"


