# HeartSync Console

Internal admin dashboard for the HeartSync Flutter app. Built with React (Vite) frontend on port 5000 and an Express backend on port 3001.

## Architecture

- **Frontend**: React + Vite at `client/` — served on port 5000
- **Backend**: Express.js at `server/` — runs on localhost:3001
- **Firebase**: firebase-admin SDK on server only; never exposes keys to frontend

## Running

```
npm run dev
```

This runs both the Vite dev server (port 5000) and the Express API (port 3001) concurrently.

## Environment secrets

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (paste raw JSON) |
| `REVENUECAT_WEBHOOK_SECRET` | RevenueCat webhook auth header value |

Without `FIREBASE_SERVICE_ACCOUNT`, the app runs in **demo mode** with mock data. Use "Demo mode" on the login screen to explore without Firebase.

## Sections

1. **Dashboard** — stats overview and 7-day activity chart
2. **Couples** — searchable couple management, grant premium, suspend
3. **Moderation** — content reports queue with dismiss/remove actions
4. **Revenue** — RevenueCat events and revenue chart
5. **AI Usage** — per-couple AI cost monitoring
6. **Notifications** — broadcast push to all users
7. **Feature Flags** — toggle flags + rollout % control

## User preferences

- Dark theme UI with rose/pink primary color (#e05c7e)
- Mock/demo mode works without any Firebase config
