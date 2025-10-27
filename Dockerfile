# 运维管理系统 Docker 镜像
# 基于AlmaLinux 9.2

FROM almalinux:9.2

# 设置标签
LABEL maintainer="Ops Management System"
LABEL version="1.0.0"
LABEL description="运维管理系统 - AlmaLinux 9.2"

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production
ENV PYTHONPATH=/app

# 安装系统依赖
RUN dnf update -y && \
    dnf install -y python3.9 python3.9-pip python3.9-devel sqlite-devel openssl-devel libffi-devel && \
    dnf clean all

# 创建应用用户
RUN useradd -r -s /bin/false -d /app -c "Ops Management Service User" opsuser

# 设置工作目录
WORKDIR /app

# 复制应用文件
COPY requirements.txt .
COPY app.py .
COPY config.py .
COPY start_app.py .

# 复制模板和静态文件
COPY templates/ ./templates/
COPY static/ ./static/ 2>/dev/null || true

# 安装Python依赖
RUN python3.9 -m pip install --no-cache-dir -r requirements.txt

# 创建必要的目录
RUN mkdir -p /app/data /app/logs /var/log/ops-management && \
    chown -R opsuser:opsuser /app /var/log/ops-management

# 切换到应用用户
USER opsuser

# 暴露端口
EXPOSE 5000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# 启动命令
CMD ["python3.9", "start_app.py"]


