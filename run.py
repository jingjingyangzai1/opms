#!/usr/bin/env python3
"""
运维管理系统启动脚本
"""
import os
import sys
from app import app, create_tables, start_background_tasks

def main():
    """主函数"""
    # 设置环境变量
    os.environ.setdefault('FLASK_ENV', 'development')
    
    # 初始化数据库
    with app.app_context():
        create_tables()
        print("[OK] 数据库初始化完成")
    
    # 启动后台任务
    start_background_tasks()
    print("[OK] 后台任务已启动")
    
    # 启动Flask应用
    print(">> 运维管理系统启动中...")
    print(">> 访问地址: http://localhost:5000")
    print(">> 日志文件: ops_management.log")
    print(">> 按 Ctrl+C 停止服务")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,
        use_reloader=False  # 避免后台任务重复启动
    )

if __name__ == '__main__':
    main()