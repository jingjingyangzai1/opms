#!/bin/bash

# 运维管理系统 Docker 部署脚本
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
CONTAINER_NAME="ops-management"
IMAGE_NAME="ops-management:latest"
COMPOSE_FILE="docker-compose.yml"

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

# 检查Docker是否安装
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，正在安装..."
        install_docker
    else
        log_info "Docker已安装: $(docker --version)"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，正在安装..."
        install_docker_compose
    else
        log_info "Docker Compose已安装: $(docker-compose --version)"
    fi
}

# 安装Docker
install_docker() {
    log_step "安装Docker..."
    
    # 安装Docker
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    log_info "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_step "安装Docker Compose..."
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_info "Docker Compose安装完成"
}

# 创建数据目录
create_directories() {
    log_step "创建数据目录..."
    
    mkdir -p ./data
    mkdir -p ./logs
    mkdir -p /var/log/ops-management
    
    # 设置权限
    chmod 755 ./data ./logs
    chmod 755 /var/log/ops-management
    
    log_info "数据目录创建完成"
}

# 创建环境变量文件
create_env_file() {
    log_step "创建环境变量文件..."
    
    if [[ ! -f .env ]]; then
        cat > .env << EOF
# 运维管理系统环境变量
SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:////app/data/ops_management.db
FLASK_ENV=production
EOF
        log_info "环境变量文件创建完成"
    else
        log_info "环境变量文件已存在"
    fi
}

# 构建Docker镜像
build_image() {
    log_step "构建Docker镜像..."
    
    docker build -t "$IMAGE_NAME" .
    log_info "Docker镜像构建完成"
}

# 停止现有容器
stop_existing_containers() {
    log_step "停止现有容器..."
    
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME"
        log_info "现有容器已停止"
    fi
    
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm "$CONTAINER_NAME"
        log_info "现有容器已删除"
    fi
}

# 启动服务
start_service() {
    log_step "启动服务..."
    
    # 使用Docker Compose启动服务
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log_info "服务启动成功"
    else
        log_error "服务启动失败"
        docker-compose logs
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙..."
    
    if systemctl is-active --quiet firewalld; then
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
    echo "  运维管理系统Docker部署完成"
    echo "=========================================="
    echo "容器名称: $CONTAINER_NAME"
    echo "镜像名称: $IMAGE_NAME"
    echo "数据目录: $(pwd)/data"
    echo "日志目录: $(pwd)/logs"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):5000"
    echo
    echo "管理命令:"
    echo "  启动服务: docker-compose up -d"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo "  查看状态: docker-compose ps"
    echo "  查看日志: docker-compose logs -f"
    echo "  进入容器: docker exec -it $CONTAINER_NAME /bin/bash"
    echo
    echo "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统Docker部署脚本"
    echo "  适用于AlmaLinux 9.2系统"
    echo "=========================================="
    echo
    
    check_root
    check_docker
    create_directories
    create_env_file
    build_image
    stop_existing_containers
    start_service
    configure_firewall
    show_deployment_info
    
    log_info "Docker部署完成！"
}

# 执行主函数
main "$@"


