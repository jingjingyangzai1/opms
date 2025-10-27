import React, { useState, useEffect } from 'react'
import { 
  Table, 
  Button, 
  Space, 
  Modal, 
  Form, 
  Input, 
  Select, 
  message, 
  Popconfirm, 
  Tag,
  Typography,
  Card,
  Row,
  Col,
  Statistic
} from 'antd'
import { 
  PlusOutlined, 
  ReloadOutlined, 
  PoweroffOutlined, 
  PlayCircleOutlined,
  DatabaseOutlined,
  ThunderboltOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined
} from '@ant-design/icons'
import dayjs from 'dayjs'

const { Title } = Typography
const { Option } = Select

interface TrainingAsset {
  id: string
  name: string
  type: string
  status: 'online' | 'offline' | 'maintenance'
  ip: string
  port: number
  cpu: number
  memory: number
  gpu: number
  lastUpdate: string
  description: string
}

const TrainingSystemAssets: React.FC = () => {
  const [assets, setAssets] = useState<TrainingAsset[]>([])
  const [loading, setLoading] = useState(false)
  const [modalVisible, setModalVisible] = useState(false)
  const [editingAsset, setEditingAsset] = useState<TrainingAsset | null>(null)
  const [form] = Form.useForm()

  // 模拟数据
  useEffect(() => {
    const mockAssets: TrainingAsset[] = [
      {
        id: '1',
        name: 'GPU训练节点-01',
        type: 'GPU训练服务器',
        status: 'online',
        ip: '192.168.1.101',
        port: 22,
        cpu: 85,
        memory: 78,
        gpu: 92,
        lastUpdate: dayjs().subtract(5, 'minute').format('YYYY-MM-DD HH:mm:ss'),
        description: 'NVIDIA A100 80GB GPU训练节点'
      },
      {
        id: '2',
        name: 'GPU训练节点-02',
        type: 'GPU训练服务器',
        status: 'online',
        ip: '192.168.1.102',
        port: 22,
        cpu: 65,
        memory: 82,
        gpu: 88,
        lastUpdate: dayjs().subtract(3, 'minute').format('YYYY-MM-DD HH:mm:ss'),
        description: 'NVIDIA V100 32GB GPU训练节点'
      },
      {
        id: '3',
        name: '存储节点-01',
        type: '存储服务器',
        status: 'maintenance',
        ip: '192.168.1.103',
        port: 22,
        cpu: 45,
        memory: 60,
        gpu: 0,
        lastUpdate: dayjs().subtract(1, 'hour').format('YYYY-MM-DD HH:mm:ss'),
        description: '高速存储节点，用于模型和数据存储'
      },
      {
        id: '4',
        name: '计算节点-01',
        type: 'CPU计算服务器',
        status: 'offline',
        ip: '192.168.1.104',
        port: 22,
        cpu: 0,
        memory: 0,
        gpu: 0,
        lastUpdate: dayjs().subtract(2, 'hour').format('YYYY-MM-DD HH:mm:ss'),
        description: '高性能CPU计算节点'
      }
    ]
    setAssets(mockAssets)
  }, [])

  const handleAdd = () => {
    setEditingAsset(null)
    form.resetFields()
    setModalVisible(true)
  }

  const handleEdit = (record: TrainingAsset) => {
    setEditingAsset(record)
    form.setFieldsValue(record)
    setModalVisible(true)
  }

  const handleDelete = (id: string) => {
    setAssets(assets.filter(asset => asset.id !== id))
    message.success('删除成功！')
  }

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields()
      const now = dayjs().format('YYYY-MM-DD HH:mm:ss')
      
      if (editingAsset) {
        // 编辑
        setAssets(assets.map(asset => 
          asset.id === editingAsset.id 
            ? { ...asset, ...values, lastUpdate: now }
            : asset
        ))
        message.success('更新成功！')
      } else {
        // 新增
        const newAsset: TrainingAsset = {
          id: Date.now().toString(),
          ...values,
          lastUpdate: now,
          status: 'offline'
        }
        setAssets([...assets, newAsset])
        message.success('添加成功！')
      }
      
      setModalVisible(false)
      form.resetFields()
    } catch (error) {
      console.error('Validation failed:', error)
    }
  }

  const handleRestart = (record: TrainingAsset) => {
    setLoading(true)
    setTimeout(() => {
      setAssets(assets.map(asset => 
        asset.id === record.id 
          ? { ...asset, status: 'online', lastUpdate: dayjs().format('YYYY-MM-DD HH:mm:ss') }
          : asset
      ))
      setLoading(false)
      message.success(`${record.name} 重启成功！`)
    }, 2000)
  }

  const handleShutdown = (record: TrainingAsset) => {
    setLoading(true)
    setTimeout(() => {
      setAssets(assets.map(asset => 
        asset.id === record.id 
          ? { ...asset, status: 'offline', lastUpdate: dayjs().format('YYYY-MM-DD HH:mm:ss') }
          : asset
      ))
      setLoading(false)
      message.success(`${record.name} 已关机！`)
    }, 1500)
  }

  const getStatusTag = (status: string) => {
    const statusConfig = {
      online: { color: 'green', text: '在线', icon: <CheckCircleOutlined /> },
      offline: { color: 'red', text: '离线', icon: <CloseCircleOutlined /> },
      maintenance: { color: 'orange', text: '维护中', icon: <ThunderboltOutlined /> }
    }
    const config = statusConfig[status as keyof typeof statusConfig]
    return (
      <Tag color={config.color} icon={config.icon}>
        {config.text}
      </Tag>
    )
  }

  const columns = [
    {
      title: '资产名称',
      dataIndex: 'name',
      key: 'name',
      render: (text: string) => (
        <Space>
          <DatabaseOutlined style={{ color: '#00d4ff' }} />
          <span style={{ color: '#ffffff' }}>{text}</span>
        </Space>
      )
    },
    {
      title: '类型',
      dataIndex: 'type',
      key: 'type',
      render: (text: string) => (
        <Tag color="blue">{text}</Tag>
      )
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => getStatusTag(status)
    },
    {
      title: 'IP地址',
      dataIndex: 'ip',
      key: 'ip',
      render: (text: string) => (
        <span style={{ color: '#00d4ff', fontFamily: 'monospace' }}>{text}</span>
      )
    },
    {
      title: 'CPU使用率',
      dataIndex: 'cpu',
      key: 'cpu',
      render: (value: number) => (
        <span style={{ color: value > 80 ? '#ff4d4f' : '#52c41a' }}>
          {value}%
        </span>
      )
    },
    {
      title: '内存使用率',
      dataIndex: 'memory',
      key: 'memory',
      render: (value: number) => (
        <span style={{ color: value > 80 ? '#ff4d4f' : '#52c41a' }}>
          {value}%
        </span>
      )
    },
    {
      title: 'GPU使用率',
      dataIndex: 'gpu',
      key: 'gpu',
      render: (value: number) => (
        <span style={{ color: value > 80 ? '#ff4d4f' : '#52c41a' }}>
          {value}%
        </span>
      )
    },
    {
      title: '最后更新',
      dataIndex: 'lastUpdate',
      key: 'lastUpdate',
      render: (text: string) => (
        <span style={{ color: 'rgba(255, 255, 255, 0.7)' }}>{text}</span>
      )
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record: TrainingAsset) => (
        <Space>
          <Button
            type="primary"
            size="small"
            icon={<ReloadOutlined />}
            onClick={() => handleRestart(record)}
            loading={loading}
            style={{
              background: 'linear-gradient(45deg, #52c41a, #389e0d)',
              border: 'none'
            }}
          >
            重启
          </Button>
          <Button
            type="primary"
            size="small"
            icon={<PoweroffOutlined />}
            onClick={() => handleShutdown(record)}
            loading={loading}
            danger
          >
            关机
          </Button>
          <Button
            type="link"
            size="small"
            onClick={() => handleEdit(record)}
            style={{ color: '#00d4ff' }}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个资产吗？"
            onConfirm={() => handleDelete(record.id)}
            okText="确定"
            cancelText="取消"
          >
            <Button type="link" size="small" danger>
              删除
            </Button>
          </Popconfirm>
        </Space>
      )
    }
  ]

  const onlineCount = assets.filter(asset => asset.status === 'online').length
  const totalCount = assets.length
  const avgCpu = assets.length > 0 ? Math.round(assets.reduce((sum, asset) => sum + asset.cpu, 0) / assets.length) : 0
  const avgMemory = assets.length > 0 ? Math.round(assets.reduce((sum, asset) => sum + asset.memory, 0) / assets.length) : 0

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <Title level={2} style={{ color: '#ffffff', marginBottom: '16px' }}>
          <DatabaseOutlined style={{ marginRight: '12px', color: '#00d4ff' }} />
          训练系统资产管理
        </Title>
        
        <Row gutter={16} style={{ marginBottom: '24px' }}>
          <Col span={6}>
            <Card style={{ 
              background: 'rgba(0, 212, 255, 0.1)', 
              border: '1px solid rgba(0, 212, 255, 0.3)',
              borderRadius: '8px'
            }}>
              <Statistic
                title="总资产数"
                value={totalCount}
                valueStyle={{ color: '#00d4ff' }}
                prefix={<DatabaseOutlined />}
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card style={{ 
              background: 'rgba(82, 196, 26, 0.1)', 
              border: '1px solid rgba(82, 196, 26, 0.3)',
              borderRadius: '8px'
            }}>
              <Statistic
                title="在线资产"
                value={onlineCount}
                valueStyle={{ color: '#52c41a' }}
                prefix={<CheckCircleOutlined />}
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card style={{ 
              background: 'rgba(255, 193, 7, 0.1)', 
              border: '1px solid rgba(255, 193, 7, 0.3)',
              borderRadius: '8px'
            }}>
              <Statistic
                title="平均CPU使用率"
                value={avgCpu}
                suffix="%"
                valueStyle={{ color: '#ffc107' }}
                prefix={<ThunderboltOutlined />}
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card style={{ 
              background: 'rgba(255, 87, 34, 0.1)', 
              border: '1px solid rgba(255, 87, 34, 0.3)',
              borderRadius: '8px'
            }}>
              <Statistic
                title="平均内存使用率"
                value={avgMemory}
                suffix="%"
                valueStyle={{ color: '#ff5722' }}
                prefix={<ThunderboltOutlined />}
              />
            </Card>
          </Col>
        </Row>

        <div style={{ textAlign: 'right', marginBottom: '16px' }}>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
            style={{
              background: 'linear-gradient(45deg, #00d4ff, #0099cc)',
              border: 'none',
              borderRadius: '6px',
              height: '40px',
              padding: '0 24px',
              fontWeight: 'bold'
            }}
          >
            添加资产
          </Button>
        </div>
      </div>

      <Table
        columns={columns}
        dataSource={assets}
        rowKey="id"
        pagination={{
          pageSize: 10,
          showSizeChanger: true,
          showQuickJumper: true,
          showTotal: (total) => `共 ${total} 条记录`,
          style: { color: '#ffffff' }
        }}
        style={{
          background: 'rgba(255, 255, 255, 0.05)',
          borderRadius: '8px'
        }}
      />

      <Modal
        title={editingAsset ? '编辑资产' : '添加资产'}
        open={modalVisible}
        onOk={handleModalOk}
        onCancel={() => setModalVisible(false)}
        width={600}
        style={{ top: 20 }}
        okText="确定"
        cancelText="取消"
      >
        <Form
          form={form}
          layout="vertical"
          initialValues={{ port: 22 }}
        >
          <Form.Item
            name="name"
            label="资产名称"
            rules={[{ required: true, message: '请输入资产名称!' }]}
          >
            <Input placeholder="请输入资产名称" />
          </Form.Item>

          <Form.Item
            name="type"
            label="资产类型"
            rules={[{ required: true, message: '请选择资产类型!' }]}
          >
            <Select placeholder="请选择资产类型">
              <Option value="GPU训练服务器">GPU训练服务器</Option>
              <Option value="CPU计算服务器">CPU计算服务器</Option>
              <Option value="存储服务器">存储服务器</Option>
              <Option value="网络设备">网络设备</Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="ip"
            label="IP地址"
            rules={[
              { required: true, message: '请输入IP地址!' },
              { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入有效的IP地址!' }
            ]}
          >
            <Input placeholder="请输入IP地址" />
          </Form.Item>

          <Form.Item
            name="port"
            label="端口"
            rules={[{ required: true, message: '请输入端口!' }]}
          >
            <Input type="number" placeholder="请输入端口" />
          </Form.Item>

          <Form.Item
            name="description"
            label="描述"
          >
            <Input.TextArea rows={3} placeholder="请输入资产描述" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default TrainingSystemAssets
