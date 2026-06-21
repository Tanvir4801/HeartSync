const API_BASE = '/api';

let authToken = null;

export function setAuthToken(token) {
  authToken = token;
  if (token) {
    localStorage.setItem('hs_token', token);
  } else {
    localStorage.removeItem('hs_token');
  }
}

export function getStoredToken() {
  return localStorage.getItem('hs_token');
}

async function request(path, options = {}) {
  const token = authToken || getStoredToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error || 'Request failed');
  }

  return res.json();
}

export const api = {
  auth: {
    verify: (idToken) => request('/auth/verify', { method: 'POST', body: JSON.stringify({ idToken }) }),
  },
  stats: {
    get: () => request('/stats'),
  },
  couples: {
    list: (q) => request(`/couples${q ? `?q=${q}` : ''}`),
    get: (id) => request(`/couples/${id}`),
    updateSubscription: (id, tier) => request(`/couples/${id}/subscription`, { method: 'PATCH', body: JSON.stringify({ tier }) }),
    updateStatus: (id, status) => request(`/couples/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status }) }),
  },
  reports: {
    list: () => request('/reports'),
    update: (id, status) => request(`/reports/${id}`, { method: 'PATCH', body: JSON.stringify({ status }) }),
  },
  notifications: {
    broadcast: (title, body) => request('/notifications/broadcast', { method: 'POST', body: JSON.stringify({ title, body }) }),
  },
  flags: {
    list: () => request('/flags'),
    update: (id, enabled, rolloutPercent) => request(`/flags/${id}`, { method: 'PUT', body: JSON.stringify({ enabled, rolloutPercent }) }),
  },
  aiUsage: {
    list: () => request('/ai-usage'),
  },
};
