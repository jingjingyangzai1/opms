#!/bin/bash

# 运维管理系统卸载脚本
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

# 停止并禁用服务
stop_service() {
    log_step "停止服务..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        log_info "服务已停止"
    else
        log_info "服务未运行"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        systemctl disable "$SERVICE_NAME"
        log_info "服务已禁用"
    else
        log_info "服务未启用"
    fi
}

# 删除systemd服务文件
remove_systemd_service() {
    log_step "删除systemd服务文件..."
    
    if [[ -f "/etc/systemd/system/$SERVICE_NAME.service" ]]; then
        rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        systemctl daemon-reload
        log_info "systemd服务文件已删除"
    else
        log_info "systemd服务文件不存在"
    fi
}

# 删除应用目录
remove_app_directory() {
    log_step "删除应用目录..."
    
    if [[ -d "$APP_DIR" ]]; then
        rm -rf "$APP_DIR"
        log_info "应用目录已删除"
    else
        log_info "应用目录不存在"
    fi
}

# 删除日志目录
remove_log_directory() {
    log_step "删除日志目录..."
    
    if [[ -d "/var/log/$SERVICE_NAME" ]]; then
        rm -rf "/var/log/$SERVICE_NAME"
        log_info "日志目录已删除"
    else
        log_info "日志目录不存在"
    fi
}

# 删除应用用户
remove_user() {
    log_step "删除应用用户..."
    
    if id "$APP_USER" &>/dev/null; then
        userdel "$APP_USER"
        log_info "用户 $APP_USER 已删除"
    else
        log_info "用户 $APP_USER 不存在"
    fi
}

# 清理防火墙规则
cleanup_firewall() {
    log_step "清理防火墙规则..."
    
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --remove-port=5000/tcp 2>/dev/null || true
        firewall-cmd --reload
        log_info "防火墙规则已清理"
    else
        log_info "firewalld未运行，跳过防火墙清理"
    fi
}

# 显示卸载信息
show_uninstall_info() {
    log_step "卸载完成信息"
    
    echo
    echo "=========================================="
    echo "  运维管理系统卸载完成"
    echo "=========================================="
    echo "已删除的内容:"
    echo "  - 应用目录: $APP_DIR"
    echo "  - 日志目录: /var/log/$SERVICE_NAME"
    echo "  - 系统用户: $APP_USER"
    echo "  - systemd服务: $SERVICE_NAME"
    echo "  - 防火墙规则: 5000端口"
    echo
    echo "注意: 系统依赖包(Python等)未删除，如需完全清理请手动删除"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统卸载脚本"
    echo "  适用于AlmaLinux 9.2系统"
    echo "=========================================="
    echo
    
    # 确认卸载
    read -p "确定要卸载运维管理系统吗? 此操作不可逆! (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        exit 0
    fi
    
    check_root
    stop_service
    remove_systemd_service
    remove_app_directory
    remove_log_directory
    remove_user
    cleanup_firewall
    show_uninstall_info
    
    log_info "卸载完成！"
}

# 执行主函数
main "$@"


