// Firebase Cloud Messaging Service Worker
// This file is required for Firebase Messaging to work on web

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyDgdEOyErgQQBCtoLdqtY7zPh4ALWFxUBU',
  appId: '1:945981272799:web:55c34575612d57b4a9af6a',
  messagingSenderId: '945981272799',
  projectId: 'society-management-56e43',
  authDomain: 'society-management-56e43.firebaseapp.com',
  storageBucket: 'society-management-56e43.firebasestorage.app',
  measurementId: 'G-N2FTTRNE98',
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new message',
    icon: payload.notification?.icon || '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.tag || 'notification',
    data: payload.data || {},
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();

  // This looks to see if the current is already open and focuses if it is
  event.waitUntil(
    clients.matchAll({
      type: 'window'
    }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

