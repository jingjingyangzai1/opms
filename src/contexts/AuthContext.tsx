import React, { createContext, useContext, useState, useEffect } from 'react'

interface User {
  id: string
  username: string
  name: string
}

interface AuthContextType {
  user: User | null
  login: (username: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
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
    const bootstrap = async () => {
      try {
        const res = await fetch('/api/auth/me', {
          method: 'GET',
          credentials: 'include'
        })
        if (res.ok) {
          const data = await res.json()
          if (data.success && data.user) {
            setUser(data.user)
            localStorage.setItem('user', JSON.stringify(data.user))
          } else {
            setUser(null)
            localStorage.removeItem('user')
          }
        } else {
          setUser(null)
          localStorage.removeItem('user')
        }
      } catch {
        setUser(null)
        localStorage.removeItem('user')
      } finally {
        setLoading(false)
      }
    }
    bootstrap()
  }, [])

  const login = async (username: string, password: string): Promise<boolean> => {
    setLoading(true)
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ username, password })
      })
      if (!res.ok) return false
      const data = await res.json()
      if (data.success && data.user) {
        setUser(data.user)
        localStorage.setItem('user', JSON.stringify(data.user))
        return true
      }
      return false
    } catch {
      return false
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' })
    } catch {}
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
