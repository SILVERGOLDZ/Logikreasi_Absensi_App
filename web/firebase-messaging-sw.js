importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBd4mV36_toqqVOXIpJhcYfLktpRWHB9hE",
  authDomain: "logikreasi-absensi.firebaseapp.com",
  projectId: "logikreasi-absensi",
  storageBucket: "logikreasi-absensi.firebasestorage.app",
  messagingSenderId: "346154577484",
  appId: "1:346154577484:web:e81ebfa994a47e50024ee9",
});

const messaging = firebase.messaging();

// Notifikasi saat tab browser BACKGROUND / tertutup
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || "Notifikasi";
  const options = {
    body: payload.notification?.body,
    icon: payload.notification?.image, // langsung pakai URL, tanpa download manual
    data: payload.data,
  };
  self.registration.showNotification(title, options);
});

// Saat notifikasi (dari background) di-klik
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const type = event.notification.data?.type;

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ("focus" in client) {
          // kirim ke tab yang sudah terbuka, ditangkap di Dart lewat window.onMessage
          client.postMessage({ type: "notification-click", payload: type });
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow("/");
      }
    })
  );
});