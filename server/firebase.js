const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!serviceAccountJson) {
    console.warn('FIREBASE_SERVICE_ACCOUNT not set — running in mock mode');
    initialized = true;
    return;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    console.log('Firebase Admin initialized');
  } catch (err) {
    console.error('Failed to initialize Firebase Admin:', err.message);
    initialized = true;
  }
}

function getFirestore() {
  try {
    return admin.firestore();
  } catch {
    return null;
  }
}

function getAuth() {
  try {
    return admin.auth();
  } catch {
    return null;
  }
}

function getMessaging() {
  try {
    return admin.messaging();
  } catch {
    return null;
  }
}

module.exports = { initFirebase, getFirestore, getAuth, getMessaging, admin };
