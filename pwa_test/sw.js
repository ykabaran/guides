self.addEventListener('install', (event) => {
	console.log('Service worker installed');
  self.skipWaiting();
});

self.addEventListener("push", e => {
	console.log(e);
	console.log(e.data);
	self.registration.showNotification("Wohoo!!", { body: e.data.text() })
});