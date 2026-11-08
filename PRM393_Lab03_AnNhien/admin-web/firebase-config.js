// Public Firebase client configuration; no Admin SDK credential belongs here.
window.ADMIN_FIREBASE_CONFIG = {
  apiKey: 'AIzaSyC49ddhpByHjElIJ2qILgezR-imb9yEWQk',
  authDomain: 'prm393-145c9.firebaseapp.com',
  projectId: 'prm393-145c9',
  appId: '1:784239891940:web:48c5cf00af6deb700a63f1',
};
window.ADMIN_FUNCTIONS_REGION = 'asia-southeast1';
// Emulator use is explicit. Never auto-connect production login to emulators.
window.ADMIN_USE_EMULATORS = ['localhost','127.0.0.1'].includes(location.hostname) && new URLSearchParams(location.search).get('emulator') === '1';
if (window.ADMIN_USE_EMULATORS) {
  window.ADMIN_FIREBASE_CONFIG = {apiKey:'demo-key',projectId:'demo-an-nhien',authDomain:'localhost'};
}
