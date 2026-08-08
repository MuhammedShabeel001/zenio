console.log("firebase-messaging-sw.js loaded");

importScripts("https://cdnjs.cloudflare.com/ajax/libs/firebase/11.1.0/firebase-app-compat.min.js");
importScripts("https://cdnjs.cloudflare.com/ajax/libs/firebase/11.1.0/firebase-messaging-compat.min.js");


firebase.initializeApp({});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});
