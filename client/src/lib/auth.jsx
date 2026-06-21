import React, { createContext, useContext, useState, useEffect } from 'react';
import { setAuthToken, getStoredToken, api } from './api';
import { signInAdmin, signOutAdmin, loadFirebaseConfig } from './firebase';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [firebaseAvailable, setFirebaseAvailable] = useState(false);

  useEffect(() => {
    loadFirebaseConfig().then(ok => setFirebaseAvailable(!!ok)).catch(() => {});

    const token = getStoredToken();
    if (token && token !== 'mock-token') {
      api.auth.verify(token)
        .then(userData => {
          setUser(userData);
          setAuthToken(token);
        })
        .catch(() => {
          setAuthToken(null);
        })
        .finally(() => setLoading(false));
    } else if (token === 'mock-token') {
      setUser({ uid: 'mock-admin', email: 'admin@heartsync.app', isAdmin: true, mock: true });
      setLoading(false);
    } else {
      setLoading(false);
    }
  }, []);

  async function loginWithEmailPassword(email, password) {
    const idToken = await signInAdmin(email, password);
    const userData = await api.auth.verify(idToken);
    setAuthToken(idToken);
    setUser(userData);
    return userData;
  }

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
    signOutAdmin().catch(() => {});
    setAuthToken(null);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, loginWithEmailPassword, loginWithToken, loginMock, logout, firebaseAvailable }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
