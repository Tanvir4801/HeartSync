import React, { createContext, useContext, useState, useEffect } from 'react';
import { setAuthToken, getStoredToken, api } from './api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = getStoredToken();
    if (token) {
      api.auth.verify(token)
        .then(userData => {
          setUser(userData);
          setAuthToken(token);
        })
        .catch(() => {
          setAuthToken(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  async function loginWithToken(idToken) {
    const userData = await api.auth.verify(idToken);
    setAuthToken(idToken);
    setUser(userData);
    return userData;
  }

  function loginMock() {
    const mockUser = { uid: 'mock-admin', email: 'admin@heartsync.app', isAdmin: true, mock: true };
    setAuthToken('mock-token');
    setUser(mockUser);
    return mockUser;
  }

  function logout() {
    setAuthToken(null);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, loginWithToken, loginMock, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
