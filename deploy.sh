#!/bin/bash

# 运维管理系统一键离线部署脚本
# 适用于AlmaLinux 9.2系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="ops-management"
APP_USER="opsuser"
APP_GROUP="opsgroup"
APP_DIR="/opt/ops-management"
SERVICE_NAME="ops-management"
PYTHON_VERSION="3.9"

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

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    log_step "检查系统版本..."
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法确定系统版本"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "almalinux" ]] || [[ "$VERSION_ID" != "9.2" ]]; then
        log_warn "此脚本专为AlmaLinux 9.2设计，当前系统: $ID $VERSION_ID"
        read -p "是否继续安装? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_info "系统检查通过: $PRETTY_NAME"
}

# 安装依赖包
install_dependencies() {
    log_step "安装系统依赖包..."
    
    # 更新系统包
    dnf update -y
    
    # 安装基础开发工具
    dnf groupinstall -y "Development Tools"
    
    # 安装Python 3.9及相关包
    dnf install -y python3.9 python3.9-pip python3.9-devel
    
    # 安装其他依赖
    dnf install -y sqlite-devel openssl-devel libffi-devel
    
    # 创建软链接
    ln -sf /usr/bin/python3.9 /usr/bin/python3
    ln -sf /usr/bin/pip3.9 /usr/bin/pip3
    
    log_info "依赖包安装完成"
}

# 创建应用用户
create_user() {
    log_step "创建应用用户..."
    
    if ! id "$APP_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$APP_DIR" -c "Ops Management Service User" "$APP_USER"
        log_info "用户 $APP_USER 创建成功"
    else
        log_info "用户 $APP_USER 已存在"
    fi
}

# 创建应用目录
create_directories() {
    log_step "创建应用目录..."
    
    mkdir -p "$APP_DIR"/{app,logs,data,config}
    mkdir -p /var/log/"$SERVICE_NAME"
    
    # 设置权限
    chown -R "$APP_USER:$APP_GROUP" "$APP_DIR"
    chown -R "$APP_USER:$APP_GROUP" /var/log/"$SERVICE_NAME"
    
    log_info "应用目录创建完成"
}

# 部署应用文件
deploy_application() {
    log_step "部署应用文件..."
    
    # 复制应用文件
    cp -r . "$APP_DIR/app/"
    
    # 创建虚拟环境
    python3 -m venv "$APP_DIR/venv"
    source "$APP_DIR/venv/bin/activate"
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装Python依赖
    pip install -r "$APP_DIR/app/requirements.txt"
    
    # 设置权限
    chown -R "$APP_USER:$APP_GROUP" "$APP_DIR"
    chmod +x "$APP_DIR/app/app.py"
    
    log_info "应用文件部署完成"
}

# 创建配置文件
create_config() {
    log_step "创建配置文件..."
    
    cat > "$APP_DIR/config/config.py" << EOF
import os

class ProductionConfig:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key-change-this-in-production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///' + os.path.join(os.path.dirname(os.path.abspath(__file__)), '../data/ops_management.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # 日志配置
    LOG_LEVEL = 'INFO'
    LOG_FILE = '/var/log/ops-management/app.log'
    
    # 连接配置
    CONNECTION_TIMEOUT = 5
    SSH_TIMEOUT = 10
    CONNECTION_TEST_INTERVAL = 30
    
    # 安全配置
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = None

class DevelopmentConfig(ProductionConfig):
    DEBUG = True
    LOG_LEVEL = 'DEBUG'
EOF

    # 创建环境变量文件
    cat > "$APP_DIR/config/.env" << EOF
FLASK_ENV=production
SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///$APP_DIR/data/ops_management.db
EOF

    chown -R "$APP_USER:$APP_GROUP" "$APP_DIR/config"
    chmod 600 "$APP_DIR/config/.env"
    
    log_info "配置文件创建完成"
}

# 创建systemd服务文件
create_systemd_service() {
    log_step "创建systemd服务文件..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Ops Management System
After=network.target
Wants=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_GROUP
WorkingDirectory=$APP_DIR/app
Environment=PATH=$APP_DIR/venv/bin
EnvironmentFile=$APP_DIR/config/.env
ExecStart=$APP_DIR/venv/bin/python app.py
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR /var/log/$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    log_info "systemd服务文件创建完成"
}

# 初始化数据库
init_database() {
    log_step "初始化数据库..."
    
    # 切换到应用目录
    cd "$APP_DIR/app"
    
    # 使用应用用户运行数据库初始化
    sudo -u "$APP_USER" bash -c "
        source $APP_DIR/venv/bin/activate
        export FLASK_ENV=production
        export SECRET_KEY=\$(grep SECRET_KEY $APP_DIR/config/.env | cut -d'=' -f2)
        export DATABASE_URL=\$(grep DATABASE_URL $APP_DIR/config/.env | cut -d'=' -f2)
        python -c \"
from app import app, create_tables
with app.app_context():
    create_tables()
    print('数据库初始化完成')
\"
    "
    
    log_info "数据库初始化完成"
}

# 启动服务
start_service() {
    log_step "启动服务..."
    
    # 启用服务
    systemctl enable "$SERVICE_NAME"
    
    # 启动服务
    systemctl start "$SERVICE_NAME"
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "服务启动成功"
    else
        log_error "服务启动失败"
        systemctl status "$SERVICE_NAME"
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙..."
    
    # 检查firewalld是否运行
    if systemctl is-active --quiet firewalld; then
        # 开放5000端口
        firewall-cmd --permanent --add-port=5000/tcp
        firewall-cmd --reload
        log_info "防火墙配置完成"
    else
        log_warn "firewalld未运行，请手动配置防火墙开放5000端口"
    fi
}

# 显示部署信息
show_deployment_info() {
    log_step "部署完成信息"
    
    echo
    echo "=========================================="
    echo "  运维管理系统部署完成"
    echo "=========================================="
    echo "服务名称: $SERVICE_NAME"
    echo "应用目录: $APP_DIR"
    echo "配置文件: $APP_DIR/config"
    echo "日志目录: /var/log/$SERVICE_NAME"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):5000"
    echo
    echo "管理命令:"
    echo "  启动服务: systemctl start $SERVICE_NAME"
    echo "  停止服务: systemctl stop $SERVICE_NAME"
    echo "  重启服务: systemctl restart $SERVICE_NAME"
    echo "  查看状态: systemctl status $SERVICE_NAME"
    echo "  查看日志: journalctl -u $SERVICE_NAME -f"
    echo
    echo "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统一键离线部署脚本"
    echo "  适用于AlmaLinux 9.2系统"
    echo "=========================================="
    echo
    
    check_root
    check_system
    install_dependencies
    create_user
    create_directories
    deploy_application
    create_config
    create_systemd_service
    init_database
    start_service
    configure_firewall
    show_deployment_info
    
    log_info "部署完成！"
}

# 执行主函数
main "$@"


