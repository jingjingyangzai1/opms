#!/bin/bash

# 运维管理系统部署测试脚本
# 用于验证部署是否成功

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SERVICE_NAME="ops-management"
TEST_URL="http://localhost:5000"
TIMEOUT=30

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

# 检查服务状态
check_service_status() {
    log_step "检查服务状态..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "服务正在运行"
        return 0
    else
        log_error "服务未运行"
        return 1
    fi
}

# 检查端口监听
check_port_listening() {
    log_step "检查端口监听..."
    
    if netstat -tlnp | grep -q ":5000 "; then
        log_info "端口5000正在监听"
        return 0
    else
        log_error "端口5000未监听"
        return 1
    fi
}

# 检查HTTP响应
check_http_response() {
    log_step "检查HTTP响应..."
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL" --connect-timeout 10)
    
    if [[ "$response_code" == "200" ]]; then
        log_info "HTTP响应正常 (200)"
        return 0
    elif [[ "$response_code" == "302" ]]; then
        log_info "HTTP响应正常 (302 - 重定向到登录页面)"
        return 0
    else
        log_error "HTTP响应异常 (状态码: $response_code)"
        return 1
    fi
}

# 检查登录页面
check_login_page() {
    log_step "检查登录页面..."
    
    local response
    response=$(curl -s "$TEST_URL/login" --connect-timeout 10)
    
    if echo "$response" | grep -q "登录"; then
        log_info "登录页面正常"
        return 0
    else
        log_error "登录页面异常"
        return 1
    fi
}

# 检查API接口
check_api_endpoints() {
    log_step "检查API接口..."
    
    # 检查资产API
    local assets_response
    assets_response=$(curl -s "$TEST_URL/api/assets?category=training" --connect-timeout 10)
    
    if echo "$assets_response" | grep -q "success"; then
        log_info "资产API正常"
    else
        log_warn "资产API异常"
    fi
    
    # 检查用户API
    local users_response
    users_response=$(curl -s "$TEST_URL/api/users" --connect-timeout 10)
    
    if echo "$users_response" | grep -q "success"; then
        log_info "用户API正常"
    else
        log_warn "用户API异常"
    fi
}

# 检查日志文件
check_log_files() {
    log_step "检查日志文件..."
    
    local log_file="/var/log/ops-management/app.log"
    local system_log="journalctl -u $SERVICE_NAME --no-pager"
    
    if [[ -f "$log_file" ]]; then
        log_info "应用日志文件存在: $log_file"
        if [[ -s "$log_file" ]]; then
            log_info "应用日志文件不为空"
        else
            log_warn "应用日志文件为空"
        fi
    else
        log_warn "应用日志文件不存在: $log_file"
    fi
    
    if $system_log | grep -q "INFO"; then
        log_info "系统日志正常"
    else
        log_warn "系统日志异常"
    fi
}

# 检查数据库
check_database() {
    log_step "检查数据库..."
    
    local db_file="/opt/ops-management/data/ops_management.db"
    
    if [[ -f "$db_file" ]]; then
        log_info "数据库文件存在: $db_file"
        
        # 检查数据库表
        local tables
        tables=$(sqlite3 "$db_file" ".tables" 2>/dev/null)
        
        if echo "$tables" | grep -q "user"; then
            log_info "用户表存在"
        else
            log_warn "用户表不存在"
        fi
        
        if echo "$tables" | grep -q "asset"; then
            log_info "资产表存在"
        else
            log_warn "资产表不存在"
        fi
    else
        log_error "数据库文件不存在: $db_file"
        return 1
    fi
}

# 检查文件权限
check_file_permissions() {
    log_step "检查文件权限..."
    
    local app_dir="/opt/ops-management"
    local log_dir="/var/log/ops-management"
    
    if [[ -d "$app_dir" ]]; then
        local owner
        owner=$(stat -c '%U:%G' "$app_dir" 2>/dev/null)
        if [[ "$owner" == "opsuser:opsgroup" ]]; then
            log_info "应用目录权限正确: $owner"
        else
            log_warn "应用目录权限异常: $owner"
        fi
    else
        log_error "应用目录不存在: $app_dir"
    fi
    
    if [[ -d "$log_dir" ]]; then
        local owner
        owner=$(stat -c '%U:%G' "$log_dir" 2>/dev/null)
        if [[ "$owner" == "opsuser:opsgroup" ]]; then
            log_info "日志目录权限正确: $owner"
        else
            log_warn "日志目录权限异常: $owner"
        fi
    else
        log_error "日志目录不存在: $log_dir"
    fi
}

# 性能测试
performance_test() {
    log_step "性能测试..."
    
    local start_time
    local end_time
    local response_time
    
    start_time=$(date +%s%N)
    curl -s "$TEST_URL" > /dev/null
    end_time=$(date +%s%N)
    
    response_time=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $response_time -lt 1000 ]]; then
        log_info "响应时间正常: ${response_time}ms"
    else
        log_warn "响应时间较慢: ${response_time}ms"
    fi
}

# 显示测试结果
show_test_results() {
    log_step "测试结果汇总"
    
    echo
    echo "=========================================="
    echo "  运维管理系统部署测试结果"
    echo "=========================================="
    echo "服务状态: $(systemctl is-active $SERVICE_NAME)"
    echo "端口监听: $(netstat -tlnp | grep ':5000 ' | wc -l) 个进程"
    echo "HTTP响应: $(curl -s -o /dev/null -w '%{http_code}' $TEST_URL)"
    echo "访问地址: $TEST_URL"
    echo
    echo "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "  运维管理系统部署测试脚本"
    echo "=========================================="
    echo
    
    local test_passed=0
    local test_total=0
    
    # 运行测试
    test_total=$((test_total + 1))
    if check_service_status; then
        test_passed=$((test_passed + 1))
    fi
    
    test_total=$((test_total + 1))
    if check_port_listening; then
        test_passed=$((test_passed + 1))
    fi
    
    test_total=$((test_total + 1))
    if check_http_response; then
        test_passed=$((test_passed + 1))
    fi
    
    test_total=$((test_total + 1))
    if check_login_page; then
        test_passed=$((test_passed + 1))
    fi
    
    check_api_endpoints
    check_log_files
    check_database
    check_file_permissions
    performance_test
    
    show_test_results
    
    echo
    echo "测试通过: $test_passed/$test_total"
    
    if [[ $test_passed -eq $test_total ]]; then
        log_info "所有测试通过！部署成功！"
        exit 0
    else
        log_error "部分测试失败，请检查部署状态"
        exit 1
    fi
}

# 执行主函数
main "$@"


