import React, { createContext, useContext, useState, useEffect } from 'react'

interface User {
  id: string
  username: string
  name: string
}

interface AuthContextType {
  user: User | null
  login: (username: string, password: string) => Promise<boolean>
  logout: () => void
  loading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // 检查本地存储中的用户信息
    const savedUser = localStorage.getItem('user')
    if (savedUser) {
      setUser(JSON.parse(savedUser))
    }
    setLoading(false)
  }, [])

  const login = async (username: string, password: string): Promise<boolean> => {
    setLoading(true)
    
    // 模拟登录API调用
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // 简单的模拟验证（实际项目中应该调用真实的API）
    if (username === 'admin' && password === 'admin123') {
      const userData: User = {
        id: '1',
        username: 'admin',
        name: '系统管理员'
      }
      setUser(userData)
      localStorage.setItem('user', JSON.stringify(userData))
      setLoading(false)
      return true
    }
    
    setLoading(false)
    return false
  }

  const logout = () => {
    setUser(null)
    localStorage.removeItem('user')
  }

  const value = {
    user,
    login,
    logout,
    loading
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
