#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
运维管理系统服务测试脚本
"""

import requests
import json
import time

def test_service():
    """测试服务功能"""
    base_url = "http://localhost:5000"
    
    print("=" * 50)
    print("运维管理系统服务测试")
    print("=" * 50)
    
    try:
        # 测试主页重定向
        print("1. 测试主页重定向...")
        response = requests.get(base_url, allow_redirects=False)
        print(f"   状态码: {response.status_code}")
        if response.status_code == 302:
            print("   [OK] 主页重定向正常")
        else:
            print("   [ERROR] 主页重定向异常")
        
        # 测试登录页面
        print("\n2. 测试登录页面...")
        response = requests.get(f"{base_url}/login")
        print(f"   状态码: {response.status_code}")
        if response.status_code == 200 and "运维管理系统" in response.text:
            print("   [OK] 登录页面加载正常")
        else:
            print("   [ERROR] 登录页面加载异常")
        
        # 测试浏览器兼容性页面
        print("\n3. 测试浏览器兼容性页面...")
        response = requests.get(f"{base_url}/browser-compatibility")
        print(f"   状态码: {response.status_code}")
        if response.status_code == 200 and "浏览器兼容性检测" in response.text:
            print("   [OK] 浏览器兼容性页面加载正常")
        else:
            print("   [ERROR] 浏览器兼容性页面加载异常")
        
        # 测试API接口
        print("\n4. 测试API接口...")
        try:
            response = requests.get(f"{base_url}/api/assets?category=training")
            print(f"   状态码: {response.status_code}")
            if response.status_code == 302:  # 未登录会重定向
                print("   [OK] API接口认证正常")
            else:
                print("   [WARNING] API接口状态异常")
        except Exception as e:
            print(f"   [ERROR] API接口测试失败: {e}")
        
        print("\n" + "=" * 50)
        print("测试完成！")
        print("=" * 50)
        print(f"服务地址: {base_url}")
        print("默认账号: admin")
        print("默认密码: admin123")
        print("浏览器兼容性检测: http://localhost:5000/browser-compatibility")
        print("=" * 50)
        
    except requests.exceptions.ConnectionError:
        print("[ERROR] 无法连接到服务，请确保服务正在运行")
    except Exception as e:
        print(f"[ERROR] 测试过程中发生错误: {e}")

if __name__ == "__main__":
    test_service()
