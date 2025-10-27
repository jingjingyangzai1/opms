from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from flask_socketio import SocketIO, emit
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timezone
import os
import json
import paramiko
import socket
import threading
import time
import logging
import uuid
from config import config

# 获取配置
config_name = os.environ.get('FLASK_ENV', 'default')
app = Flask(__name__)
app.config.from_object(config[config_name])

# 配置日志记录
logging.basicConfig(
    level=getattr(logging, app.config['LOG_LEVEL']),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(app.config['LOG_FILE']),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

db = SQLAlchemy(app)
socketio = SocketIO(app, cors_allowed_origins="*")
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# SSH会话管理器
class SSHSessionManager:
    def __init__(self):
        self.sessions = {}  # {session_id: {'ssh': ssh, 'channel': channel, ...}}
        self.lock = threading.Lock()
    
    def create_session(self, asset):
        """创建SSH交互式会话"""
        session_id = str(uuid.uuid4())
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(
                hostname=asset.ip_address,
                port=asset.port,
                username=asset.username,
                password=asset.password,
                timeout=app.config['SSH_TIMEOUT']
            )
            
            # 创建交互式shell通道
            channel = ssh.invoke_shell(term='xterm', width=1000, height=40)
            channel.settimeout(1)
            
            # 等待初始提示符就绪
            time.sleep(0.5)
            
            # 清空初始输出
            while channel.recv_ready():
                channel.recv(4096)
            
            with self.lock:
                self.sessions[session_id] = {
                    'ssh': ssh,
                    'channel': channel,
                    'asset_id': asset.id,
                    'created_at': datetime.now(timezone.utc)
                }
            
            logger.info(f"SSH交互式会话创建成功: {session_id} for {asset.name}")
            return session_id, True, "SSH连接成功"
        except Exception as e:
            logger.error(f"SSH会话创建失败: {e}")
            return None, False, str(e)
    
    def execute_command(self, session_id, command):
        """在交互式shell中执行命令"""
        if session_id not in self.sessions:
            return None, False, "会话不存在"
        
        try:
            import re
            channel = self.sessions[session_id]['channel']
            
            # 发送命令到交互式shell
            channel.send(command + '\n')
            
            # 接收输出（带超时）
            output = ""
            start_time = time.time()
            timeout = 5.0  # 5秒超时
            last_output = ""
            no_output_count = 0
            
            while time.time() - start_time < timeout:
                if channel.recv_ready():
                    chunk = channel.recv(4096).decode('utf-8', errors='ignore')
                    output += chunk
                    last_output = output
                    no_output_count = 0
                else:
                    no_output_count += 1
                    time.sleep(0.1)
                    
                    # 如果连续多次没有新输出，认为命令已完成
                    if no_output_count > 10:
                        break
                
                # 如果输出不再增加，可能命令已执行完成
                if not channel.recv_ready():
                    time.sleep(0.1)
            
            # 清除ANSI转义码和控制字符
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            output = ansi_escape.sub('', output)
            
            # 移除终端控制字符
            output = output.replace('\r', '')
            
            # 移除命令回显（用户输入的命令） - 更严格的匹配
            command_escaped = re.escape(command)
            # 匹配命令后可能跟换行符的情况，包括多种格式
            output = re.sub(rf'{command_escaped}[\r\n\s]*', '', output)
            
            # 移除所有可能的终端提示符格式
            # 包括: 0;root@localhost:~, 0:root@localhost:~, root@localhost:~ 等
            output = re.sub(r'\d+[;:]root@localhost:[^\n]*[\n]?', '', output)
            output = re.sub(r'root@localhost:[^\n]*[\n]?', '', output)
            
            # 移除标准提示符（包括 [root@localhost ~]#）
            output = re.sub(r'\[root@localhost ~\]#\s*[\n]*', '', output)
            output = re.sub(r'\[root@localhost\s+~\]#\s*[\n]*', '', output)
            
            # 移除所有以数字开头、分号结尾的提示符（如 "0;"）
            output = re.sub(r'\d+;\s*[\n]?', '', output)
            
            # 移除空行
            output = re.sub(r'\n{3,}', '\n\n', output)
            
            # 移除开头的空行
            output = output.lstrip('\n')
            
            return output, True, ""
        except Exception as e:
            logger.error(f"命令执行失败: {e}")
            return None, False, str(e)
    
    def send_raw_data(self, session_id, data):
        """发送原始数据到SSH通道（用于Tab补全等）"""
        if session_id not in self.sessions:
            return None, False, "会话不存在"
        
        try:
            channel = self.sessions[session_id]['channel']
            channel.send(data)
            
            # 接收补全结果
            output = ""
            start_time = time.time()
            timeout = 2.0  # 2秒超时
            
            while time.time() - start_time < timeout:
                if channel.recv_ready():
                    chunk = channel.recv(4096).decode('utf-8', errors='ignore')
                    output += chunk
                else:
                    if output:
                        break
                    time.sleep(0.1)
            
            # 清除ANSI转义码
            import re
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            output = ansi_escape.sub('', output)
            output = output.replace('\r', '')
            
            return output, True, ""
        except Exception as e:
            logger.error(f"原始数据发送失败: {e}")
            return None, False, str(e)
    
    def close_session(self, session_id):
        """关闭SSH会话"""
        if session_id in self.sessions:
            try:
                if 'channel' in self.sessions[session_id]:
                    self.sessions[session_id]['channel'].close()
                self.sessions[session_id]['ssh'].close()
            except:
                pass
            with self.lock:
                del self.sessions[session_id]
            logger.info(f"SSH会话已关闭: {session_id}")

# 全局SSH会话管理器
ssh_manager = SSHSessionManager()

# 数据库模型
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

class Asset(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False, index=True)
    asset_type = db.Column(db.String(50), nullable=False, index=True)
    status = db.Column(db.String(20), default='offline', index=True)
    ip_address = db.Column(db.String(15), nullable=False, unique=True, index=True)
    port = db.Column(db.Integer, default=22)
    username = db.Column(db.String(50))
    password = db.Column(db.String(100))
    cpu_usage = db.Column(db.Integer, default=0)
    memory_usage = db.Column(db.Integer, default=0)
    disk_usage = db.Column(db.Integer, default=0)
    description = db.Column(db.Text)
    last_update = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    category = db.Column(db.String(50), nullable=False, index=True)  # 'training' or 'physical'

# 操作日志模型已移除

@login_manager.user_loader
def load_user(user_id):
    return db.session.get(User, int(user_id))

# 操作日志记录函数已移除

def test_asset_connection(asset):
    """测试资产连接状态"""
    try:
        logger.info(f"开始测试资产连接: {asset.name} ({asset.ip_address}:{asset.port})")
        
        # 首先测试网络连通性
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(app.config['CONNECTION_TIMEOUT'])
        result = sock.connect_ex((asset.ip_address, asset.port))
        sock.close()
        
        if result != 0:
            logger.warning(f"网络连接失败: {asset.name}")
            return False, "网络连接失败"
        
        logger.info(f"网络连通性测试成功: {asset.name}")
        
        # 如果配置了SSH凭据，进一步测试SSH连接
        if asset.username and asset.password:
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(asset.ip_address, port=asset.port, username=asset.username, 
                           password=asset.password, timeout=app.config['SSH_TIMEOUT'])
                ssh.close()
                logger.info(f"SSH连接测试成功: {asset.name}")
                return True, "SSH连接正常"
            except Exception as e:
                logger.warning(f"SSH连接失败: {asset.name} - {e}")
                return False, f"SSH连接失败：{str(e)}"
        else:
            logger.info(f"网络连通但无SSH凭据: {asset.name}")
            return True, "网络连接正常"
            
    except Exception as e:
        logger.error(f"连接测试异常: {asset.name} - {e}")
        return False, f"连接测试失败：{str(e)}"

def execute_ssh_command(hostname, port, username, password, command):
    """通过SSH执行远程命令"""
    try:
        logger.info(f"执行SSH命令: {hostname}:{port} - {command}")
        
        # 创建SSH客户端
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # 连接SSH服务器
        ssh.connect(hostname, port=port, username=username, password=password, timeout=app.config['SSH_TIMEOUT'])
        
        # 执行命令
        stdin, stdout, stderr = ssh.exec_command(command)
        
        # 获取输出
        output = stdout.read().decode('utf-8')
        error = stderr.read().decode('utf-8')
        
        # 关闭连接
        ssh.close()
        
        if error:
            logger.warning(f"命令执行出错: {hostname} - {error}")
        else:
            logger.info(f"命令执行成功: {hostname}")
        
        return True, output, error
    except paramiko.AuthenticationException:
        logger.error(f"SSH认证失败: {hostname}")
        return False, "", "SSH认证失败：用户名或密码错误"
    except paramiko.SSHException as e:
        logger.error(f"SSH连接错误: {hostname} - {e}")
        return False, "", f"SSH连接错误：{str(e)}"
    except socket.timeout:
        logger.error(f"连接超时: {hostname}")
        return False, "", "连接超时：无法连接到目标主机"
    except Exception as e:
        logger.error(f"执行命令异常: {hostname} - {e}")
        return False, "", f"执行命令时发生错误：{str(e)}"

def background_connection_test():
    """后台连接测试任务 - 自动检测资产在线/离线状态"""
    logger.info("后台连接测试任务启动 - 自动检测资产状态")
    while True:
        try:
            with app.app_context():
                assets = Asset.query.all()
                if assets:
                    logger.info(f"开始自动测试 {len(assets)} 个资产的连接状态")
                    
                    online_count = 0
                    offline_count = 0
                    maintenance_count = 0
                    
                    for asset in assets:
                        # 跳过手动设置为维护状态的资产
                        if asset.status == 'maintenance':
                            maintenance_count += 1
                            continue
                        
                        # 测试连接
                        is_online, message = test_asset_connection(asset)
                        
                        # 更新状态
                        old_status = asset.status
                        if is_online:
                            asset.status = 'online'
                            online_count += 1
                        else:
                            asset.status = 'offline'
                            offline_count += 1
                        
                        # 如果状态发生变化，更新最后更新时间
                        if old_status != asset.status:
                            asset.last_update = datetime.now(timezone.utc)
                            logger.info(f"资产状态变更: {asset.name} ({asset.ip_address}) 从 {old_status} 变更为 {asset.status} - {message}")
                        else:
                            # 即使状态没变，也更新最后测试时间
                            asset.last_update = datetime.now(timezone.utc)
                    
                    # 提交所有更改
                    db.session.commit()
                    
                    # 记录测试结果统计
                    logger.info(f"自动测试完成 - 在线: {online_count}, 离线: {offline_count}, 维护: {maintenance_count}")
                else:
                    logger.info("没有资产需要测试")
                    
        except Exception as e:
            logger.error(f"后台连接测试出错: {str(e)}")
        
        # 使用配置的测试间隔
        time.sleep(app.config['CONNECTION_TEST_INTERVAL'])

# 启动后台任务
def start_background_tasks():
    """启动后台任务"""
    thread = threading.Thread(target=background_connection_test, daemon=True)
    thread.start()
    logger.info("后台连接测试任务已启动")

# 路由
@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('training_assets'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        logger.info(f"用户登录尝试: {username}")
        
        user = User.query.filter_by(username=username).first()
        
        if user and check_password_hash(user.password_hash, password):
            login_user(user)
            logger.info(f"用户登录成功: {username}")
            return redirect(url_for('training_assets'))
        else:
            logger.warning(f"用户登录失败: {username}")
            flash('用户名或密码错误！', 'error')
    
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logger.info(f"用户登出: {current_user.username}")
    logout_user()
    return redirect(url_for('login'))

# 仪表盘功能已移除

# 修改密码功能已移至用户管理页面

# 操作日志功能已移除

@app.route('/users')
@login_required
def users():
    """用户管理页面"""
    users = User.query.all()
    return render_template('users.html', users=users)

@app.route('/api/users', methods=['GET', 'POST', 'PUT', 'DELETE'])
@login_required
def api_users():
    """用户管理API"""
    try:
        if request.method == 'GET':
            users = User.query.all()
            users_data = []
            for user in users:
                users_data.append({
                    'id': user.id,
                    'username': user.username,
                    'email': getattr(user, 'email', '') or '',
                    'created_at': user.created_at.strftime('%Y-%m-%d %H:%M:%S') if user.created_at else '',
                    'is_active': getattr(user, 'is_active', True)
                })
            return jsonify({'success': True, 'data': users_data})
        
        elif request.method == 'POST':
            # 创建新用户
            data = request.get_json()
            username = data.get('username', '').strip()
            password = data.get('password', '').strip()
            email = data.get('email', '').strip()
            
            if not username or not password:
                return jsonify({'success': False, 'message': '用户名和密码不能为空！'})
            
            if len(password) < 6:
                return jsonify({'success': False, 'message': '密码长度至少6位！'})
            
            # 检查用户名是否已存在
            existing_user = User.query.filter_by(username=username).first()
            if existing_user:
                return jsonify({'success': False, 'message': '用户名已存在！'})
            
            user = User(
                username=username,
                password_hash=generate_password_hash(password),
                name=username,  # 使用用户名作为默认名称
                email=email if email else None,
                is_active=True
            )
            
            db.session.add(user)
            db.session.commit()
            
            logger.info(f"用户创建成功: {username}")
            return jsonify({'success': True, 'message': '用户创建成功！'})
        
        elif request.method == 'PUT':
            # 更新用户信息
            data = request.get_json()
            user_id = data.get('id')
            new_password = data.get('password', '').strip()
            email = data.get('email', '').strip()
            
            user = User.query.get(user_id)
            if not user:
                return jsonify({'success': False, 'message': '用户不存在！'})
            
            # 更新密码
            if new_password:
                if len(new_password) < 6:
                    return jsonify({'success': False, 'message': '密码长度至少6位！'})
                user.password_hash = generate_password_hash(new_password)
            
            # 更新邮箱
            if hasattr(user, 'email'):
                user.email = email if email else None
            if hasattr(user, 'is_active'):
                user.is_active = data.get('is_active', getattr(user, 'is_active', True))
            
            db.session.commit()
            
            logger.info(f"用户信息更新成功: {user.username}")
            return jsonify({'success': True, 'message': '用户信息更新成功！'})
        
        elif request.method == 'DELETE':
            # 删除用户
            user_id = request.args.get('id')
            user = User.query.get(user_id)
            
            if not user:
                return jsonify({'success': False, 'message': '用户不存在！'})
            
            # 不能删除当前登录用户
            if user.id == current_user.id:
                return jsonify({'success': False, 'message': '不能删除当前登录用户！'})
            
            username = user.username
            db.session.delete(user)
            db.session.commit()
            
            logger.info(f"用户删除成功: {username}")
            return jsonify({'success': True, 'message': '用户删除成功！'})
    
    except Exception as e:
        logger.error(f"用户管理API错误: {e}")
        return jsonify({'success': False, 'message': f'操作失败: {str(e)}'}), 500

@app.route('/training-assets')
@login_required
def training_assets():
    assets = Asset.query.filter_by(category='training').all()
    return render_template('training_assets.html', assets=assets)

@app.route('/physical-servers')
@login_required
def physical_servers():
    assets = Asset.query.filter_by(category='physical').all()
    return render_template('physical_servers.html', assets=assets)


@app.route('/api/assets', methods=['GET', 'POST'])
@login_required
def api_assets():
    try:
        if request.method == 'GET':
            category = request.args.get('category', 'training')
            logger.info(f"获取资产列表: {category}")
            
            assets = Asset.query.filter_by(category=category).all()
            
            assets_data = []
            for asset in assets:
                assets_data.append({
                    'id': asset.id,
                    'name': asset.name,
                    'type': asset.asset_type,
                    'status': asset.status,
                    'ip': asset.ip_address,
                    'port': asset.port,
                    'username': asset.username,
                    'password': asset.password,
                    'cpu': asset.cpu_usage,
                    'memory': asset.memory_usage,
                    'disk': asset.disk_usage,
                    'description': asset.description,
                    'last_update': asset.last_update.strftime('%Y-%m-%d %H:%M:%S')
                })
            
            logger.info(f"返回 {len(assets_data)} 个资产")
            return jsonify(assets_data)
        
        elif request.method == 'POST':
            data = request.get_json()
            
            # 检查IP地址是否已存在
            existing_asset = Asset.query.filter_by(ip_address=data['ip']).first()
            if existing_asset:
                return jsonify({'success': False, 'message': f'IP地址 {data["ip"]} 已存在，请使用其他IP地址！'})
            
            # 根据资产类型自动分配类别
            asset_type = data['type']
            if asset_type == '虚拟资产':
                category = 'training'  # 虚拟资产显示在训练系统资产列表
            elif asset_type == '物理资产':
                category = 'physical'  # 物理资产显示在主控物理服务器列表
            else:
                category = 'training'  # 默认分配到训练系统资产
            
            asset = Asset(
                name=data['name'],
                asset_type=asset_type,
                ip_address=data['ip'],
                port=data['port'],
                username=data.get('username', ''),
                password=data.get('password', ''),
                description=data.get('description', ''),
                category=category
            )
            
            db.session.add(asset)
            db.session.commit()
            
            logger.info(f"资产添加成功: {data['name']} (类型: {asset_type}, 类别: {category})")
            return jsonify({'success': True, 'message': f'资产添加成功！已分配到{"训练系统资产" if category == "training" else "主控物理服务器"}列表'})
    
    except Exception as e:
        logger.error(f"API错误: {e}")
        return jsonify({'success': False, 'message': f'操作失败: {str(e)}'}), 500

@app.route('/api/assets/<int:asset_id>/terminal/connect', methods=['POST'])
@login_required
def ssh_terminal_connect(asset_id):
    """创建SSH会话"""
    try:
        asset = Asset.query.get_or_404(asset_id)
        
        # 检查是否有SSH凭据
        if not asset.username or not asset.password:
            return jsonify({'success': False, 'error': '缺少SSH凭据'}), 400
        
        session_id, success, message = ssh_manager.create_session(asset)
        
        if success:
            return jsonify({'success': True, 'session_id': session_id, 'message': message})
        else:
            return jsonify({'success': False, 'error': message}), 500
            
    except Exception as e:
        logger.error(f"SSH会话创建错误: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/assets/<int:asset_id>/terminal', methods=['POST'])
@login_required
def ssh_terminal_execute(asset_id):
    """在SSH会话中执行命令"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        command = data.get('command', '')
        
        if not session_id:
            return jsonify({'success': False, 'error': '缺少session_id'}), 400
        
        output, success, error = ssh_manager.execute_command(session_id, command)
        
        if success:
            return jsonify({'success': True, 'output': output or '', 'error': error or ''})
        else:
            return jsonify({'success': False, 'error': error}), 500
            
    except Exception as e:
        logger.error(f"命令执行错误: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/assets/<int:asset_id>/terminal/disconnect', methods=['POST'])
@login_required
def ssh_terminal_disconnect(asset_id):
    """断开SSH会话"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        
        if session_id:
            ssh_manager.close_session(session_id)
        
        return jsonify({'success': True, 'message': '会话已断开'})
            
    except Exception as e:
        logger.error(f"SSH会话断开错误: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/assets/<int:asset_id>/terminal/tab', methods=['POST'])
@login_required
def ssh_terminal_tab(asset_id):
    """Tab键补全"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({'success': False, 'error': '缺少session_id'}), 400
        
        # 发送Tab字符
        output, success, error = ssh_manager.send_raw_data(session_id, '\t')
        
        if success:
            return jsonify({'success': True, 'output': output or ''})
        else:
            return jsonify({'success': False, 'error': error}), 500
            
    except Exception as e:
        logger.error(f"Tab补全错误: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/assets/<int:asset_id>', methods=['PUT', 'DELETE'])
@login_required
def api_asset_detail(asset_id):
    try:
        asset = Asset.query.get_or_404(asset_id)
        logger.info(f"处理资产操作: {asset.name} (ID: {asset_id})")
        
        if request.method == 'PUT':
            data = request.get_json()
            action = data.get('action')
        
            if action == 'restart':
                # 检查是否有SSH凭据
                if not asset.username or not asset.password:
                    return jsonify({'success': False, 'message': '缺少SSH凭据，无法执行重启操作'})
                
                # 通过SSH执行重启命令
                success, output, error = execute_ssh_command(
                    asset.ip_address, 
                    asset.port, 
                    asset.username, 
                    asset.password, 
                    'sudo reboot'
                )
                
                if success:
                    asset.status = 'maintenance'
                    asset.cpu_usage = 0
                    asset.memory_usage = 0
                    asset.disk_usage = 0
                    asset.last_update = datetime.now(timezone.utc)
                    db.session.commit()
                    return jsonify({'success': True, 'message': f'{asset.name} 重启指令已发送，正在重启...'})
                else:
                    return jsonify({'success': False, 'message': f'重启失败：{error}'})
            
            elif action == 'shutdown':
                # 检查是否有SSH凭据
                if not asset.username or not asset.password:
                    return jsonify({'success': False, 'message': '缺少SSH凭据，无法执行关机操作'})
                
                # 通过SSH执行关机命令
                success, output, error = execute_ssh_command(
                    asset.ip_address, 
                    asset.port, 
                    asset.username, 
                    asset.password, 
                    'sudo shutdown -h now'
                )
                
                if success:
                    asset.status = 'offline'
                    asset.cpu_usage = 0
                    asset.memory_usage = 0
                    asset.disk_usage = 0
                    asset.last_update = datetime.now(timezone.utc)
                    db.session.commit()
                    return jsonify({'success': True, 'message': f'{asset.name} 关机指令已发送，正在关机...'})
                else:
                    return jsonify({'success': False, 'message': f'关机失败：{error}'})
        
            
            elif action == 'update':
                # 检查IP地址是否已被其他资产使用
                new_ip = data.get('ip', asset.ip_address)
                if new_ip != asset.ip_address:  # 只有IP地址发生变化时才检查
                    existing_asset = Asset.query.filter(Asset.ip_address == new_ip, Asset.id != asset.id).first()
                    if existing_asset:
                        return jsonify({'success': False, 'message': f'IP地址 {new_ip} 已存在，请使用其他IP地址！'})
                
                asset.name = data.get('name', asset.name)
                asset.asset_type = data.get('type', asset.asset_type)
                asset.ip_address = new_ip
                asset.port = data.get('port', asset.port)
                asset.username = data.get('username', asset.username)
                asset.password = data.get('password', asset.password)
                asset.description = data.get('description', asset.description)
                asset.last_update = datetime.now(timezone.utc)
                db.session.commit()
                return jsonify({'success': True, 'message': '资产更新成功！'})
        
        elif request.method == 'DELETE':
            logger.info(f"删除资产: {asset.name}")
            db.session.delete(asset)
            db.session.commit()
            return jsonify({'success': True, 'message': '资产删除成功！'})
    
    except Exception as e:
        logger.error(f"资产操作错误: {e}")
        return jsonify({'success': False, 'message': f'操作失败: {str(e)}'}), 500

# 初始化数据库
def create_tables():
    db.create_all()
    
    # 创建默认管理员用户
    if not User.query.filter_by(username='admin').first():
        admin = User(
            username='admin',
            password_hash=generate_password_hash('admin123'),
            name='系统管理员'
        )
        db.session.add(admin)
        db.session.commit()
    
    # 创建示例数据
    if not Asset.query.first():
        sample_assets = [
               Asset(name='GPU训练节点-01', asset_type='虚拟资产', status='online',
                     ip_address='192.168.1.101', cpu_usage=85, memory_usage=78, disk_usage=92,
                     description='NVIDIA A100 80GB GPU训练节点', category='training'),
               Asset(name='GPU训练节点-02', asset_type='虚拟资产', status='online',
                     ip_address='192.168.1.102', cpu_usage=65, memory_usage=82, disk_usage=88,
                     description='NVIDIA V100 32GB GPU训练节点', category='training'),
               Asset(name='存储节点-01', asset_type='物理资产', status='maintenance',
                     ip_address='192.168.1.103', cpu_usage=45, memory_usage=60, disk_usage=75,
                     description='高速存储节点，用于模型和数据存储', category='training'),
               Asset(name='主控服务器-01', asset_type='物理资产', status='online',
                     ip_address='192.168.1.201', cpu_usage=70, memory_usage=65, disk_usage=45,
                     description='主控物理服务器，负责系统管理', category='physical'),
               Asset(name='主控服务器-02', asset_type='物理资产', status='online',
                     ip_address='192.168.1.202', cpu_usage=55, memory_usage=72, disk_usage=38,
                     description='备用主控服务器', category='physical'),
               Asset(name='网络设备-01', asset_type='物理资产', status='offline',
                     ip_address='192.168.1.203', cpu_usage=0, memory_usage=0, disk_usage=0,
                     description='核心网络交换机', category='physical')
        ]
        
        for asset in sample_assets:
            db.session.add(asset)
        
        db.session.commit()

if __name__ == '__main__':
    with app.app_context():
        create_tables()
        # 启动后台连接测试任务
        start_background_tasks()
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
