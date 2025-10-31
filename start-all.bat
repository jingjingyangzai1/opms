@echo off
chcp 65001 >nul
echo ================================================
echo 一键启动 运维管理系统（前后端分离 开发模式）
echo ================================================

REM 定位到脚本所在目录
pushd %~dp0

echo.
echo [1/4] 检查 Python 环境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 Python，请先安装 Python 3.9+ 并加入 PATH
    goto :END
)

echo.
echo [2/4] 安装后端依赖（pip install -r requirements.txt）...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo 警告: 后端依赖安装出现问题，请检查网络或 pip 源
)

echo.
echo [3/4] 启动后端（Flask 5000）...
start "ops-backend" cmd /K "python run.py"

echo.
echo [4/4] 检查 Node.js/npm 环境...
node -v >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 Node.js，请先安装 Node.js 16+（包含 npm）
    echo 仅后端已启动，可访问: http://localhost:5000
    goto :INFO
)

echo 安装前端依赖（npm install）...
cmd /C npm install

echo 启动前端（Vite 3000）...
start "ops-frontend" cmd /K "npm run dev"

:INFO
echo.
echo ================================================
echo 已发起启动：
echo   后端: http://localhost:5000
echo   前端: http://localhost:3000
echo 
echo 局域网访问请使用本机IP：
echo   后端: http://<你的电脑IP>:5000
echo   前端: http://<你的电脑IP>:3000
echo 
echo 提示：首次运行可能需要等待依赖安装完成。
echo 关闭方式：在各自窗口中按 Ctrl+C 停止。
echo ================================================

:END
popd
exit /B 0
