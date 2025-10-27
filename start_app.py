#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
运维管理系统启动脚本
适用于AlmaLinux 9.2系统
"""

import os
import sys
import logging
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# 设置环境变量
os.environ.setdefault('FLASK_ENV', 'production')

# 导入应用
from app import app, create_tables

def setup_logging():
    """设置日志配置"""
    log_dir = Path('/var/log/ops-management')
    log_dir.mkdir(parents=True, exist_ok=True)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('/var/log/ops-management/app.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )

def main():
    """主函数"""
    try:
        # 设置日志
        setup_logging()
        logger = logging.getLogger(__name__)
        
        logger.info("正在启动运维管理系统...")
        
        # 初始化数据库
        with app.app_context():
            create_tables()
            logger.info("数据库初始化完成")
        
        # 启动应用
        logger.info("应用启动成功，监听端口: 5000")
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=False,
            threaded=True
        )
        
    except Exception as e:
        logging.error(f"应用启动失败: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()


