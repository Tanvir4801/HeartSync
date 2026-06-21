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

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });

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
    broadcast: (title, body, opts = {}) => request('/notifications/broadcast', { method: 'POST', body: JSON.stringify({ title, body, ...opts }) }),
    scheduled: () => request('/notifications/scheduled'),
    cancelScheduled: (id) => request(`/notifications/scheduled/${id}`, { method: 'DELETE' }),
    history: () => request('/notifications/history'),
  },
  flags: {
    list: () => request('/flags'),
    update: (id, enabled, rolloutPercent) => request(`/flags/${id}`, { method: 'PUT', body: JSON.stringify({ enabled, rolloutPercent }) }),
  },
  aiUsage: {
    list: () => request('/ai-usage'),
  },
  ai: {
    loveLetter: (occasion, tone, coupleId) => request('/ai/love-letter', { method: 'POST', body: JSON.stringify({ occasion, tone, coupleId }) }),
    caption: (description, coupleId) => request('/ai/caption', { method: 'POST', body: JSON.stringify({ description, coupleId }) }),
    monthlyRecap: (coupleId, month, year, stats) => request('/ai/monthly-recap', { method: 'POST', body: JSON.stringify({ coupleId, month, year, stats }) }),
    generate: (type, tone, context, coupleId) => request('/ai/generate', { method: 'POST', body: JSON.stringify({ type, tone, context, coupleId }) }),
  },
  themes: {
    list: () => request('/themes/themes'),
    save: (theme) => request('/themes/themes', { method: 'POST', body: JSON.stringify(theme) }),
    delete: (id) => request(`/themes/themes/${id}`, { method: 'DELETE' }),
    badges: () => request('/themes/badges'),
    saveBadge: (badge) => request('/themes/badges', { method: 'POST', body: JSON.stringify(badge) }),
    deleteBadge: (id) => request(`/themes/badges/${id}`, { method: 'DELETE' }),
  },
  support: {
    tickets: (status) => request(`/support/tickets${status && status !== 'all' ? `?status=${status}` : ''}`),
    reply: (id, message) => request(`/support/tickets/${id}/reply`, { method: 'POST', body: JSON.stringify({ message }) }),
    setStatus: (id, status) => request(`/support/tickets/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status }) }),
  },
  analytics: {
    funnel: () => request('/analytics/funnel'),
    retention: () => request('/analytics/retention'),
  },
  audit: {
    list: (action) => request(`/audit${action ? `?action=${action}` : ''}`),
    log: (action, targetCoupleId, detail) => request('/audit', { method: 'POST', body: JSON.stringify({ action, targetCoupleId, detail }) }),
  },
  gdpr: {
    requests: (status) => request(`/gdpr/requests${status && status !== 'all' ? `?status=${status}` : ''}`),
    export: (id) => request(`/gdpr/requests/${id}/export`, { method: 'POST' }),
    delete: (id) => request(`/gdpr/requests/${id}/delete`, { method: 'POST' }),
  },
};
