import React, { useState } from 'react'
import { Layout, Menu, Button, Avatar, Dropdown, Typography, Space } from 'antd'
import { 
  DashboardOutlined, 
  ServerOutlined, 
  DatabaseOutlined, 
  LogoutOutlined, 
  UserOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined
} from '@ant-design/icons'
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import TrainingSystemAssets from './TrainingSystemAssets'
import PhysicalServerAssets from './PhysicalServerAssets'

const { Header, Sider, Content } = Layout
const { Text } = Typography

const Dashboard: React.FC = () => {
  const [collapsed, setCollapsed] = useState(false)
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: '仪表板',
    },
    {
      key: '/training-assets',
      icon: <DatabaseOutlined />,
      label: '训练系统资产',
    },
    {
      key: '/physical-servers',
      icon: <ServerOutlined />,
      label: '主控物理服务器',
    },
  ]

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key)
  }

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: '个人资料',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: '退出登录',
      onClick: handleLogout,
    },
  ]

  return (
    <Layout style={{ minHeight: '100vh', background: 'transparent' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        style={{
          background: 'rgba(0, 0, 0, 0.3)',
          backdropFilter: 'blur(10px)',
          borderRight: '1px solid rgba(0, 212, 255, 0.3)',
        }}
        width={250}
      >
        <div style={{
          padding: '20px',
          textAlign: 'center',
          borderBottom: '1px solid rgba(0, 212, 255, 0.3)',
          marginBottom: '20px'
        }}>
          <div style={{
            fontSize: collapsed ? '24px' : '32px',
            color: '#00d4ff',
            marginBottom: collapsed ? '0' : '8px',
            transition: 'all 0.3s ease'
          }}>
            <DatabaseOutlined />
          </div>
          {!collapsed && (
            <Text style={{ 
              color: '#ffffff', 
              fontSize: '16px', 
              fontWeight: 'bold',
              display: 'block'
            }}>
              运维管理系统
            </Text>
          )}
        </div>
        
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={handleMenuClick}
          style={{
            background: 'transparent',
            border: 'none',
          }}
        />
      </Sider>

      <Layout>
        <Header style={{
          background: 'rgba(0, 0, 0, 0.3)',
          backdropFilter: 'blur(10px)',
          borderBottom: '1px solid rgba(0, 212, 255, 0.3)',
          padding: '0 24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            style={{
              fontSize: '16px',
              width: 64,
              height: 64,
              color: '#00d4ff',
              border: 'none',
              background: 'transparent'
            }}
          />
          
          <Space>
            <Text style={{ color: '#ffffff' }}>
              欢迎, {user?.name}
            </Text>
            <Dropdown
              menu={{ items: userMenuItems }}
              placement="bottomRight"
              arrow
            >
              <Avatar 
                style={{ 
                  background: 'linear-gradient(45deg, #00d4ff, #0099cc)',
                  cursor: 'pointer'
                }}
                icon={<UserOutlined />}
              />
            </Dropdown>
          </Space>
        </Header>

        <Content style={{
          margin: '24px',
          padding: '24px',
          background: 'rgba(255, 255, 255, 0.05)',
          backdropFilter: 'blur(10px)',
          borderRadius: '12px',
          border: '1px solid rgba(0, 212, 255, 0.2)',
          minHeight: 'calc(100vh - 112px)',
          overflow: 'auto'
        }}>
          <Routes>
            <Route path="/dashboard" element={
              <div style={{ textAlign: 'center', padding: '60px 0' }}>
                <div style={{
                  fontSize: '64px',
                  color: '#00d4ff',
                  marginBottom: '24px',
                  animation: 'glow 2s ease-in-out infinite'
                }}>
                  <DashboardOutlined />
                </div>
                <h1 style={{ color: '#ffffff', marginBottom: '16px' }}>
                  欢迎使用运维管理系统
                </h1>
                <p style={{ color: 'rgba(255, 255, 255, 0.7)', fontSize: '16px' }}>
                  请选择左侧菜单开始管理您的资产
                </p>
              </div>
            } />
            <Route path="/training-assets" element={<TrainingSystemAssets />} />
            <Route path="/physical-servers" element={<PhysicalServerAssets />} />
          </Routes>
        </Content>
      </Layout>
    </Layout>
  )
}

export default Dashboard
