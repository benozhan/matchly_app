importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey:            "AIzaSyBLK5S_G0oAM7untHyyEua75dDNDkffH30",
  authDomain:        "matchly-app-a09a2.firebaseapp.com",
  projectId:         "matchly-app-a09a2",
  storageBucket:     "matchly-app-a09a2.firebasestorage.app",
  messagingSenderId: "911799540941",
  appId:             "1:911799540941:web:54416ecb53f5db63845d84",
});

const messaging = firebase.messaging();

// Uygulama arka planda veya kapalıyken gelen bildirimleri yakala
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Background message:", payload);

  const title = payload.notification?.title ?? "Matchly";
  const options = {
    body: payload.notification?.body ?? "",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(title, options);
});
