import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword, signOut } from 'firebase/auth';

let app = null;
let auth = null;
let configLoaded = false;

export async function loadFirebaseConfig() {
  if (configLoaded) return true;
  try {
    const res = await fetch('/api/config');
    const data = await res.json();
    const cfg = data.firebase;
    if (cfg?.authDomain && cfg?.apiKey) {
      app = initializeApp(cfg);
      auth = getAuth(app);
      configLoaded = true;
      return true;
    }
  } catch (err) {
    console.warn('Could not load Firebase config from server:', err.message);
  }
  return false;
}

export async function signInAdmin(email, password) {
  await loadFirebaseConfig();
  if (!auth) throw new Error('Firebase not initialized — check GOOGLE_API_KEY secret');
  const credential = await signInWithEmailAndPassword(auth, email, password);
  return credential.user.getIdToken();
}

export async function signOutAdmin() {
  if (auth) await signOut(auth).catch(() => {});
}

export function isFirebaseConfigured() {
  return !!configLoaded;
}
