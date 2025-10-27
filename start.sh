#!/bin/bash

echo "================================================"
echo "运维管理系统启动脚本"
echo "================================================"
echo ""
echo "正在检查Python环境..."
python3 --version
if [ $? -ne 0 ]; then
    echo "错误: 未找到Python环境，请先安装Python 3.7+"
    exit 1
fi

echo ""
echo "正在安装依赖包..."
pip3 install -r requirements.txt

echo ""
echo "正在启动系统..."
echo "================================================"
echo "系统功能:"
echo "  • 用户登录/退出"
echo "  • 训练系统资产管理"
echo "  • 主控物理服务器管理"
echo "  • 资产操作(重启/关机)"
echo "  • 科技风格UI界面"
echo "================================================"
echo "访问地址: http://localhost:5000"
echo "默认账号: admin"
echo "默认密码: admin123"
echo "================================================"
echo ""

python3 run.py
